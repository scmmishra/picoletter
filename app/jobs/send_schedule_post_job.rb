# This job is triggered every 1 minute and it looks ahead 2 minutes to find any posts that are scheduled to be published in the next 2 minutes.
# This difference in time is to ensure that the job has enough time to process the posts before they are published.
class SendSchedulePostJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[SendScheduledPost] Sending published post to subscribers"

    posts_to_send.pluck(:id).each do |post_id|
      post = Post.claim_for_processing(post_id)
      next unless post

      Rails.logger.info "[SendScheduledPost] Sending post #{post.title} to subscribers"
      begin
        post.publish_and_send
        # Note: publish_and_send already sets status to "published" - no duplicate update needed
      rescue StandardError => e
        Rails.logger.error "[SendScheduledPost] Error sending post #{post.title}: #{e.message}"
        post.update(status: "draft")
        raise e
      end
    end
  end

  def posts_to_send
    # Only get posts scheduled for this exact minute to prevent overlap
    time = Time.current.beginning_of_minute
    Post.drafts.where(scheduled_at: time..(time + 59.seconds))
  end
end
