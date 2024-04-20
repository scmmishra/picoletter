class SendPostJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 100

  def perform(post_id)
    post = Post.find(post_id)
    newsletter = post.newsletter

    html_content = ApplicationController.render(
      template: "publish",
      assigns: { post: post, newsletter: newsletter },
      layout: false
    )

    from_email = newsletter.sending_address || "#{newsletter.slug}@mail.picoletter.com"

    newsletter.subscribers.verified.find_in_batches(batch_size: BATCH_SIZE) do |batch_subscribers|
      Rails.logger.info "[PostMailer] Sending #{post.title} to #{batch_subscribers.count} subscribers"

      batch_params = batch_subscribers.map do |subscriber|
        {
          to: [ subscriber.email ],
          from: from_email,
          reply_to: newsletter.reply_to || newsletter.user.email,
          subject: post.title,
          html: html_content
        }
      end

      Resend::Batch.send(batch_params)
    end
  end
end
