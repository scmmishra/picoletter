class SendPostJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 100
  UNSUBSCRIBE_PLACEHOLDER = "{{unsubscribe_link}}"

  def perform(post_id)
    @post = Post.find(post_id)
    @newsletter = @post.newsletter

    @html_content = render_html_content
    @from_email = @newsletter.full_sending_address


    @newsletter.subscribers.verified.find_in_batches(batch_size: BATCH_SIZE) do |batch_subscribers|
      send_batch(batch_subscribers)
    end
  end

  private

  def send_batch(subscribers)
    Rails.logger.info "[PostMailer] Sending #{@post.title} to #{subscribers.count} subscribers"
    batch_params = subscribers.map do |subscriber|
      prepare_email_payload(subscriber)
    end

    Resend::Batch.send(batch_params)
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
