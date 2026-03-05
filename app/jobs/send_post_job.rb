class SendPostJob < BaseSendJob
  queue_as :default
  attr_reader :post, :newsletter

  BATCH_SIZE = AppConfig.get("SEND_POST_BATCH_SIZE", 50)

  def perform(post_id)
    setup_post(post_id)
    return unless post.processing?

    Rails.cache.delete(cache_key(post.id, "send_aborted"))
    send_context = build_send_context
    prepare_post_for_sending
    dispatch_to_subscribers(send_context)
  rescue StandardError => error
    handle_send_failure(error)
    raise
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

  def build_send_context
    tenant_name = SES::TenantPreflightService.new(newsletter).ensure_ready!
    { tenant_name: tenant_name }
  end

  def dispatch_to_subscribers(send_context)
    return if total_batches.zero?

    verified_subscribers.in_batches(of: BATCH_SIZE) do |batch_scope|
      SendPostBatchJob.perform_later(post.id, batch_scope.pluck(:id), send_context)
    end
  end

  def total_batches
    (verified_subscribers.count.to_f / BATCH_SIZE).ceil
  end

  def verified_subscribers
    @verified_subscribers ||= newsletter.subscribers.verified
  end

  def handle_send_failure(error)
    return if post.blank?

    Rails.cache.write(cache_key(post.id, "send_aborted"), true, expires_in: 2.hours)
    post.fail_sending! if post.processing?
    Rails.error.report(
      error,
      context: { post_id: post.id, newsletter_id: newsletter&.id }
    )
  end
end
