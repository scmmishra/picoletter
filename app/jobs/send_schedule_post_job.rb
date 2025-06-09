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
        # Post is already claimed and validated - just queue for sending
        SendPostJob.perform_later(post.id)
        # Note: Status will be set to "published" by SendPostBatchJob when all batches complete
      rescue StandardError => e
        RorVsWild.record_error(e, context: { post: post_id })
        Rails.logger.error "[SendScheduledPost] Error sending post #{post.title}: #{e.message}"
        post.update(status: "draft")
        raise e
      end
    end
  end

  def posts_to_send
    # 1 minute before and after current time to handle job timing variations
    # Atomic claiming prevents duplicates across multiple job runs
    Post.drafts.where(scheduled_at: 1.minute.ago..1.minute.from_now)
  end
end
