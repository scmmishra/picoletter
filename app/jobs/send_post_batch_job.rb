class SendPostBatchJob < ApplicationJob
  queue_as :default
  after_perform :update_batch_count

  UNSUBSCRIBE_PLACEHOLDER = "{{unsubscribe_link}}"

  def perform(post_id, batch_subscribers)
    @post = Post.find(post_id)
    @newsletter = @post.newsletter
    @html_content = render_html_content
    @from_email = @newsletter.full_sending_address

    send_batch(batch_subscribers)
  end

  private

  def update_batch_count
    post_id = @post.id
    remaining_batches = Rails.cache.decrement("post_#{post_id}_batches_remaining")

    @post.publish if remaining_batches <= 0
  end

  def send_batch(batch_subscribers)
    Rails.logger.info "[PostMailer] Sending #{@post.title} to #{batch_subscribers.count} subscribers"
    batch_params = batch_subscribers.map do |subscriber|
      prepare_email_payload(subscriber)
    end

    response = Resend::Batch.send(batch_params)
    sends = response[:data].map do |payload|
      {
        email_id: payload["id"],
        post_id: @post.id,
        status: :sent
      }
    end

    Email.insert_all(sends)
  end

  def prepare_email_payload(subscriber)
    token = subscriber.generate_unsubscribe_token
    unsub_url = unsubscribe_url(token, @newsletter.slug)
    html = @html_content.gsub(UNSUBSCRIBE_PLACEHOLDER, unsubscribe_link(unsub_url))

    {
      to: [ subscriber.email ],
      from: @from_email,
      reply_to: @newsletter.reply_to || @newsletter.user.email,
      subject: @post.title,
      html: html,
      headers: {
        'List-Unsubscribe': "<#{unsub_url}>",
        'List-Unsubscribe-Post': "List-Unsubscribe=One-Click",
        'X-Newsletter-id': "picoletter-#{@newsletter.id}-#{@post.id}-#{subscriber.id}"
      }
    }
  end

  def render_html_content
    ApplicationController.render(
      template: "publish",
      assigns: { post: @post, newsletter: @newsletter },
      layout: false
    )
  end

  def unsubscribe_link(url)
    "<a href=\"#{url}\">unsubscribe</a>"
  end

  def unsubscribe_url(token, slug)
    Rails.application.routes.url_helpers.unsubscribe_url(slug: slug, token: token)
  end
end
