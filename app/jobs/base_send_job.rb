class BaseSendJob < ApplicationJob
  private

  def cache_key(post_id, suffix)
    "post_#{post_id}_#{suffix}"
  end

  def rendered_html_content(post, newsletter)
    return render_html_content(post, newsletter) if Rails.env.development?

    Rails.cache.fetch(cache_key(post.id, "html_content"), expires_in: 2.hours) do
      render_html_content(post, newsletter)
    end
  end

  def rendered_text_content(post, newsletter)
    return render_text_content(post, newsletter) if Rails.env.development?

    Rails.cache.fetch(cache_key(post.id, "text_content"), expires_in: 2.hours) do
      render_text_content(post, newsletter)
    end
  end

  def render_html_content(post, newsletter)
    ApplicationController.render(
      template: "publish",
      assigns: { post: post, newsletter: newsletter },
      layout: false
    )
  end

  def render_text_content(post, newsletter)
    ApplicationController.render(
      template: "publish",
      assigns: { post: post, newsletter: newsletter },
      layout: false,
      formats: [ :text ]
    )
  end
end
