class SendPostJob < ApplicationJob
  queue_as :default
  attr_reader :post, :newsletter

  BATCH_SIZE = 100

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
    cache_rendered_content
    mark_as_processing
  end

  def dispatch_to_subscribers
    newsletter.subscribers.verified.find_in_batches(batch_size: BATCH_SIZE) do |batch|
      SendPostBatchJob.perform_later(post.id, batch)
    end
  end

  def cache_rendered_content
    Rails.cache.write(cache_key("html_content"), rendered_html_content)
    Rails.cache.write(cache_key("text_content"), rendered_text_content)
  end

  def mark_as_processing
    post.update(status: :processing)
    Rails.cache.write(cache_key("batches_remaining"), total_batches)
  end

  def total_batches
    (newsletter.subscribers.verified.count.to_f / BATCH_SIZE).ceil
  end

  def rendered_html_content
    ApplicationController.render(
      template: "publish",
      assigns: { post: post, newsletter: newsletter },
      layout: false,
    )
  end

  def rendered_text_content
    ApplicationController.render(
      template: "publish",
      assigns: { post: post, newsletter: newsletter },
      layout: false,
      formats: [ :text ]
    )
  end

  def cache_key(suffix)
    "post_#{post.id}_#{suffix}"
  end
end
