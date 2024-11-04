class SendPostBatchJob < ApplicationJob
  queue_as :default
  after_perform :update_batch_count

  UNSUBSCRIBE_PLACEHOLDER = "{{unsubscribe_link}}"

  def perform(post_id, batch_subscribers)
    @post = Post.find(post_id)
    @newsletter = @post.newsletter
    @html_content = get_html_content
    @text_content = get_text_content
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
    sends = batch_subscribers.map do |subscriber|
      token = subscriber.generate_unsubscribe_token
      unsub_url = unsubscribe_url(token, @newsletter.slug)
      html = @html_content.gsub(UNSUBSCRIBE_PLACEHOLDER, unsubscribe_link(unsub_url))

      response = SES::EmailService.send(
          to: [ subscriber.email ],
          from: @from_email,
          reply_to: @newsletter.reply_to || @newsletter.user.email,
          subject: @post.title,
          html: @html_content,
          text: @text_content,
          headers: {
            'List-Unsubscribe': "<#{unsub_url}>",
            'List-Unsubscribe-Post': "List-Unsubscribe=One-Click",
            'X-Newsletter-id': "picoletter-#{@newsletter.id}-#{@post.id}-#{subscriber.id}"
          }
        )

      {
        post_id: @post.id,
        subscriber_id: subscriber.id,
        email_id: response.message_id
      }
    end

    Email.insert_all(sends)
  end

  def get_html_content
    Rails.cache.fetch(cache_key("html_content")) do
      rendered_html_content
    end
  end

  def get_text_content
    Rails.cache.fetch(cache_key("text_content")) do
      rendered_text_content
    end
  end

  def cache_key(suffix)
    "post_#{@post.id}_#{suffix}"
  end

  def rendered_html_content
    ApplicationController.render(
      template: "publish",
      assigns: { post: post, newsletter: newsletter },
      layout: false,
    )
  end

  def rendered_text_content
    ApplicationController.render(
      template: "publish",
      assigns: { post: post, newsletter: newsletter },
      layout: false,
      formats: [ :text ]
    )
  end

  def unsubscribe_link(url)
    "<a href=\"#{url}\">unsubscribe</a>"
  end

  def unsubscribe_url(token, slug)
    Rails.application.routes.url_helpers.unsubscribe_url(slug: slug, token: token)
  end
end
