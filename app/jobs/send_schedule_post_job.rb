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
        Rails.error.report(e, context: { post: post_id })
        Rails.logger.error "[SendScheduledPost] Error sending post #{post.title}: #{e.message}"
        post.update(status: "draft")
      end
    end
  end

  def posts_to_send
    # Always pick all due drafts so delayed job runs can catch up.
    Post.draft.where(scheduled_at: ..Time.current)
  end
end
