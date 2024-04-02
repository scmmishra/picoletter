class SendPublishedPostJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[SendPublishedPostJob] Sending published post to subscribers"

    # find post which is shceduled in the next 5 minutes
    posts_to_send.each do |post|
      puts "Sending post #{post.title} to subscribers"
      # PostMailer.with(post: post).publish.deliver_later
    end
  end

  def posts_to_send
    Post.drafts.where(published_at: Time.now..(Time.now + 5.minutes))
  end
end
