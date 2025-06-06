class MonitorStuckPostsJob < ApplicationJob
  queue_as :default

  def perform
    stuck_posts = find_stuck_posts
    return if stuck_posts.empty?

    Rails.logger.warn "[MonitorStuckPosts] Found #{stuck_posts.count} stuck posts: #{stuck_posts.pluck(:id)}"

    # Send alert to super admins
    AdminMailer.stuck_posts_alert(stuck_posts).deliver_now
  end

  private

  def find_stuck_posts
    # Posts stuck in processing for more than 10 minutes
    Post.where(
      status: "processing",
      updated_at: ..10.minutes.ago
    )
  end
end
