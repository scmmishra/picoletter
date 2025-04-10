class SendPostService
  def initialize(post)
    @post = post
    @newsletter = @post.newsletter
    @from_email = @newsletter.full_sending_address
    @html_content = render_html_content
    @text_content = render_text_content
  end

  def send(subscribers)
    @post.update(status: :processing)
    total_batches = (@newsletter.subscribers.verified.count.to_f / BATCH_SIZE).ceil
    Rails.cache.write("post_#{post_id}_batches_remaining", total_batches)

    @newsletter.subscribers.verified.find_in_batches(batch_size: BATCH_SIZE) do |batch_subscribers|
      SendPostBatchJob.perform_later(@post.id, batch_subscribers)
    end
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
