class SendPublishedPostJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[SendPublishedPostJob] Sending published post to subscribers"

    # find post which is shceduled in the next 5 minutes
    Post.all.each do |post|
      Rails.logger.info "[SendPublishedPostJob] Sending post #{post.title} to subscribers"
      begin
        post.update(status: "processing")
        post.publish_and_send_later
        post.update(status: "published")
      rescue StandardError => e
        Rails.logger.error "[SendPublishedPostJob] Error sending post #{post.title}: #{e.message}"
        post.update(status: "draft")
        raise e
      end
    end
  end

  def posts_to_send
    Post.drafts.where(scheduled_at: Time.now..(Time.now + 5.minutes))
  end
end
