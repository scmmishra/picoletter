class SendPostJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 100

  def perform(post_id)
    @post = Post.find(post_id)
    @newsletter = @post.newsletter
    @post.update(status: :processing)

    @newsletter.subscribers.verified.find_in_batches(batch_size: BATCH_SIZE) do |batch_subscribers|
      SendPostBatchJob.perform_later(@post.id, batch_subscribers)
    end
    @post.publish
  end
end
