class SendPostJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 100

  def perform(post_id)
    @post = Post.find(post_id)
    @newsletter = @post.newsletter

    set_rendered_content_in_cache
    set_processing
    send_batches
  end

  def send_batches
    @newsletter.subscribers.verified.find_in_batches(batch_size: BATCH_SIZE) do |batch_subscribers|
      SendPostBatchJob.perform_later(@post.id, batch_subscribers)
    end
  end

  def set_rendered_content_in_cache
    Rails.cache.write("post_#{@post.id}_html_content", render_html_content)
    Rails.cache.write("post_#{@post.id}_text_content", render_text_content)
  end

  def set_processing
    @post.update(status: :processing)
    total_batches = (@newsletter.subscribers.verified.count.to_f / BATCH_SIZE).ceil
    Rails.cache.write("post_#{@post.id}_batches_remaining", total_batches)
  end

  def render_html_content
    ApplicationController.render(
      template: "publish",
      assigns: { post: @post, newsletter: @newsletter },
      layout: false
    )
  end

  def render_text_content
    ApplicationController.render(
      template: "publish",
      assigns: { post: @post, newsletter: @newsletter },
      layout: false,
      formats: [ :text ]
    )
  end
end
