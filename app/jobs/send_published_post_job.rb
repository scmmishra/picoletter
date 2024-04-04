# This job is triggered every 1 minute and it looks ahead 2 minutes to find any posts that are scheduled to be published in the next 2 minutes.
# This difference in time is to ensure that the job has enough time to process the posts before they are published.
class SendPublishedPostJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[SendPublishedPostJob] Sending published post to subscribers"

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
    Post.drafts.where(scheduled_at: (Time.now - 2.minutes)..(Time.now + 2.minutes))
  end
end
