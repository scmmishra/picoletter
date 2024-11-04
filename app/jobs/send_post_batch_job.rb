class SendPostBatchJob < BaseSendJob
  queue_as :default
  after_perform :update_batch_count
  attr_reader :post, :newsletter, :html_content, :text_content, :from_email

  UNSUBSCRIBE_PLACEHOLDER = "{{unsubscribe_link}}"

  def perform(post_id, batch_subscribers)
    initialize_post(post_id)
    send_batch(batch_subscribers)
  end

  private

  def initialize_post(post_id)
    @post = Post.find(post_id)
    @newsletter = @post.newsletter
    @html_content = rendered_html_content(post, newsletter)
    @text_content = rendered_text_content(post, newsletter)
    @from_email = newsletter.full_sending_address
  end

  def update_batch_count
    remaining_batches = Rails.cache.decrement(cache_key(post.id, "batches_remaining"))
    post.publish if remaining_batches <= 0
  end

  def send_batch(batch_subscribers)
    sends = batch_subscribers.map do |subscriber|
      response = send_email(subscriber)

      {
        post_id: post.id,
        subscriber_id: subscriber.id,
        email_id: response.message_id
      }
    end

    Email.insert_all(sends)
  end

  def send_email(subscriber)
    token = subscriber.generate_unsubscribe_token
    unsub_url = unsubscribe_url(token, newsletter.slug)
    html = html_content.gsub(UNSUBSCRIBE_PLACEHOLDER, unsubscribe_link(unsub_url))
    text = text_content.gsub(UNSUBSCRIBE_PLACEHOLDER, unsub_url)

    ses_service.send(
      to: [ subscriber.email ],
      from: from_email,
      reply_to: newsletter.reply_to.presence || newsletter.user.email,
      subject: post.title,
      html: html,
      text: text,
      headers: {
        "List-Unsubscribe" => "<#{unsub_url}>",
        "List-Unsubscribe-Post" => "List-Unsubscribe=One-Click",
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
end
