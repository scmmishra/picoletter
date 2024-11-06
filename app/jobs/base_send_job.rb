class BaseSendJob < ApplicationJob
  private

  def cache_key(post_id, suffix)
    "post_#{post_id}_#{suffix}"
  end

  def rendered_html_content(post, newsletter)
    Rails.cache.fetch(cache_key(post.id, "html_content"), expires_in: 2.hours) do
      ApplicationController.render(
        template: "publish",
        assigns: { post: post, newsletter: newsletter },
        layout: false
      )
    end
  end

  def rendered_text_content(post, newsletter)
    Rails.cache.fetch(cache_key(post.id, "text_content"), expires_in: 2.hours) do
      ApplicationController.render(
        template: "publish",
        assigns: { post: post, newsletter: newsletter },
        layout: false,
        formats: [ :text ]
      )
    end
  end
end
