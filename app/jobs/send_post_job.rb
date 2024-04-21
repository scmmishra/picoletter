class SendPostJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 100
  UNSUBSCRIBE_PLACEHOLDER = "{{unsubscribe_link}}"

  def perform(post_id)
    post = Post.find(post_id)
    newsletter = post.newsletter

    html_content = ApplicationController.render(
      template: "publish",
      assigns: { post: post, newsletter: newsletter },
      layout: false
    )

    from_email = "#{newsletter.slug}@mail.picoletter.com"
    if newsletter.use_custom_domain && newsletter.domain_verified
      from_email = "#{newsletter.title} <#{newsletter.sending_address}>"
    end


    newsletter.subscribers.verified.find_in_batches(batch_size: BATCH_SIZE) do |batch_subscribers|
      Rails.logger.info "[PostMailer] Sending #{post.title} to #{batch_subscribers.count} subscribers"

      batch_params = batch_subscribers.map do |subscriber|
        token = subscriber.generate_unsubscribe_token
        html = html_content.gsub(UNSUBSCRIBE_PLACEHOLDER, unsubscribe_link(token, newsletter.slug))

        {
          to: [ subscriber.email ],
          from: from_email,
          reply_to: newsletter.reply_to || newsletter.user.email,
          subject: post.title,
          html: html
        }
      end

      Resend::Batch.send(batch_params)
    end
  end

  private

  def unsubscribe_link(token, slug)
    url = Rails.application.routes.url_helpers.unsubscribe_url(slug: slug, token: token)
    "<a href=\"#{url}\">unsubscribe</a>"
  end
end
