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
    html = ApplicationController.render(
      template: "publish",
      assigns: { post: post, newsletter: newsletter },
      layout: false
    )

    inline_email_styles(html)
  end

  def render_text_content(post, newsletter)
    ApplicationController.render(
      template: "publish",
      assigns: { post: post, newsletter: newsletter },
      layout: false,
      formats: [ :text ]
    )
  end

  def inline_email_styles(html)
    Premailer.new(
      html,
      with_html_string: true,
      preserve_styles: false,
      remove_ids: false,
      remove_classes: false
    ).to_inline_css
  rescue StandardError => error
    Rails.logger.warn("Premailer inline CSS failed for post email: #{error.class} - #{error.message}")
    html
  end
end
