class SendPostJob < BaseSendJob
  queue_as :default
  attr_reader :post, :newsletter

  BATCH_SIZE = AppConfig.get("SEND_POST_BATCH_SIZE", 50)

  def perform(post_id)
    setup_post(post_id)
    return unless post.processing?

    prepare_post_for_sending
    dispatch_to_subscribers
  end

  private

  def setup_post(post_id)
    @post = Post.find(post_id)
    @newsletter = @post.newsletter
  end

  def prepare_post_for_sending
    if total_batches.zero?
      post.publish
      return
    end

    Rails.cache.write(cache_key(post.id, "batches_remaining"), total_batches)
  end

  def dispatch_to_subscribers
    return if total_batches.zero?

    newsletter.subscribers.verified.find_in_batches(batch_size: BATCH_SIZE) do |batch|
      SendPostBatchJob.perform_later(post.id, batch)
    end
  end

  def total_batches
    (newsletter.subscribers.verified.count.to_f / BATCH_SIZE).ceil
  end
end
