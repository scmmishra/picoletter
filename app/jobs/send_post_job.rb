class SendPostJob < BaseSendJob
  queue_as :default
  attr_reader :post, :newsletter

  BATCH_SIZE = AppConfig.get("SEND_POST_BATCH_SIZE", 50)

  def perform(post_id)
    setup_post(post_id)
    prepare_post_for_sending
    dispatch_to_subscribers
  end

  private

  def setup_post(post_id)
    @post = Post.find(post_id)
    @newsletter = @post.newsletter
  end

  def prepare_post_for_sending
    # Status and batches are now handled by SendPostService
  end

  def dispatch_to_subscribers
    SendPostService.new(post).send
  end
end
