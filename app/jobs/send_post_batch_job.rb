class SendPostBatchJob < BaseSendJob
  queue_as :default
  after_perform :update_batch_count
  attr_reader :post, :newsletter, :html_content, :text_content, :from_email, :send_context

  UNSUBSCRIBE_PLACEHOLDER = "{{unsubscribe_link}}"

  def perform(post_id, batch_subscriber_ids, send_context = {})
    initialize_post(post_id, send_context)
    return if send_aborted?

    send_batch(batch_subscriber_ids)
  rescue StandardError => error
    handle_batch_failure(error)
    raise
  end

  private

  def initialize_post(post_id, send_context)
    @post = Post.find(post_id)
    @newsletter = @post.newsletter
    @send_context = send_context.to_h.with_indifferent_access
    @html_content = rendered_html_content(post, newsletter)
    @text_content = rendered_text_content(post, newsletter)
    @from_email = newsletter.full_sending_address
  end

  def update_batch_count
    return if post.blank? || send_aborted?
    return unless post.processing?

    remaining_batches = Rails.cache.decrement(cache_key(post.id, "batches_remaining"))
    return if remaining_batches.blank?

    if remaining_batches <= 0
      @newsletter.user.update_meter(post.emails.count) if AppConfig.billing_enabled?
      post.publish
    end
  end

  def send_batch(batch_subscriber_ids)
    subscribers_for_batch(batch_subscriber_ids).each do |subscriber|
      response = send_email(subscriber)
      message_id = extract_message_id(response)

      post.emails.create!(
        id: message_id,
        subscriber_id: subscriber.id
      )
    end
  end

  def subscribers_for_batch(batch_subscriber_ids)
    subscriber_ids = Array(batch_subscriber_ids).map { |entry| entry.respond_to?(:id) ? entry.id : entry }.compact
    return [] if subscriber_ids.empty?

    subscribers_by_id = newsletter.subscribers.verified.where(id: subscriber_ids).index_by(&:id)
    subscriber_ids.filter_map { |subscriber_id| subscribers_by_id[subscriber_id.to_i] }
  end

  def send_email(subscriber)
    # TODO: Replace with a null SES service or Action Mailer's :test delivery method
    return { message_id: SecureRandom.uuid } if Rails.env.development?

    token = subscriber.generate_token_for(:unsubscribe)
    unsub_url = unsubscribe_url(token, newsletter.slug)
    unsub_email = "mailto:#{newsletter.user.email}?subject=Unsubscribe"
    html = html_content.gsub(UNSUBSCRIBE_PLACEHOLDER, unsubscribe_link(unsub_url))
    text = text_content.gsub(UNSUBSCRIBE_PLACEHOLDER, unsub_url)

    ses_service.send(
      to: [ subscriber.email ],
      from: from_email,
      tenant_name: send_context[:tenant_name],
      reply_to: newsletter.reply_to.presence || newsletter.user.email,
      subject: post.title,
      html: html,
      text: text,
      headers: {
        "List-Unsubscribe" => "<#{unsub_url}>,<#{unsub_email}>",
        "List-Unsubscribe-Post" => "List-Unsubscribe=One-Click",
        "List-ID" => list_id,
        "X-Newsletter-id" => "picoletter-#{newsletter.id}-#{post.id}-#{subscriber.id}"
      }
    )
  end

  def ses_service
    @ses_service ||= SES::EmailService.new
  end

  def unsubscribe_link(url)
    "<a ses:no-track href=\"#{url}\">unsubscribe</a>"
  end

  def unsubscribe_url(token, slug)
    Rails.application.routes.url_helpers.unsubscribe_url(slug: slug, token: token)
  end

  def list_id
    # Use a stable RFC 2919-compatible identifier so mailbox providers can classify list traffic.
    "<newsletter-#{newsletter.id}.#{list_id_domain}>"
  end

  def list_id_domain
    newsletter.sending_from.split("@").last
  end

  def extract_message_id(response)
    return response.message_id if response.respond_to?(:message_id)

    response[:message_id] || response["message_id"]
  end

  def send_aborted?
    return true if post&.failed?

    Rails.cache.read(cache_key(post.id, "send_aborted")) == true
  end

  def handle_batch_failure(error)
    return if post.blank?

    Rails.cache.write(cache_key(post.id, "send_aborted"), true, expires_in: 2.hours)
    post.fail_sending! if post.processing?
    Rails.error.report(
      error,
      context: { post_id: post.id, newsletter_id: newsletter&.id, job: self.class.name }
    )
  end
end
