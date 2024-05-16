module Embeddable
  extend ActiveSupport::Concern

  def embded_form(with_name: false)
    <<~HTML
    <form
      action="#{embed_url}"
      method="post"
      target="popupwindow"
      onsubmit="window.open('#{Rails.application.config.host}/#{slug}', 'popupwindow')"
      class="picoletter-form-embed"
    >
      #{ with_name ? "<label for=\"pico-name\">Enter your name</label>\n  <input type=\"text\" name=\"name\" id=\"pico-name\" />" : "" }

      <label for="pico-email">Enter your email</label>
      <input type="email" name="email" id="pico-email" />

      <input type="submit" value="Subscribe" />
      <p>
        <a href="#{Rails.application.config.host}?from=#{slug}" target="_blank">Built using PicoLetter.</a>
      </p>
    </form>
    HTML
  end

  def embded_form_css(with_name: false)
    <<~CSS
    :root {
      --accent: #{primary_color};
      --accent-light: color-mix(in srgb, var(--accent), white 30%);
      --accent-lightest: color-mix(in srgb, var(--accent), white 90%);
      --accent-dark: color-mix(in srgb, var(--accent), black 30%);
      --radius: 0.4rem;
    }

    .picoletter-form-embed {
      display: flex;
      flex-direction: column;
      font-family: #{font_family};
    }

    .picoletter-form-embed label {
      font-size: 0.875rem;
      margin-bottom: 0.5rem;
      font-weight: 600;
    }

    .picoletter-form-embed input[type="text"],
    .picoletter-form-embed input[type="email"] {
      padding: 0.5rem;
      border-radius: 0.25rem;
      margin-bottom: 1rem;
      border: 1px solid #ccc;
      border-radius: var(--radius);
    }

    .picoletter-form-embed input[type="submit"] {
      border: 1px solid var(--accent);
      background-color: var(--accent);
      color: var(--accent-lightest);
      padding: 0.5rem 0.9rem;
      text-decoration: none;
      line-height: normal;
      margin-bottom: 0.5rem;
      border-radius: var(--radius);
    }

    .picoletter-form-embed input[type="submit"]:hover {
      background-color: var(--accent-dark);
      border-color: var(--accent-dark);
      cursor: pointer;
    }

    .picoletter-form-embed p {
      margin-block-start: 0px;
      margin-block-end: 0px;
      font-size: 0.75rem;
      color: #666;
    }
    CSS
  end

  def theme
    # find theme config matching newsletter primary color
    Newsletter.theme_config.find { |config| config.primary == primary_color }
  end

  def codepen_payload
    payload = {
      "title" => "#{self.title} - Picoletter Embed Form",
      "private" => true,
      "html" => self.embded_form(with_name: true),
      "css" => self.embded_form_css
    }

    ERB::Util.json_escape(payload.to_json)
  end

  def font_family
    case font_preference
    when "sans-serif"
      "SF Pro Display,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Oxygen,Ubuntu,Cantarell,Open Sans,Helvetica Neue,sans-serif"
    when "serif"
      "Georgia, ui-serif, Cambria, Times New Roman, Times, serif"
    when "monospace"
      "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, Liberation Mono, Courier New, monospace"
    else
      "SF Pro Display,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Oxygen,Ubuntu,Cantarell,Open Sans,Helvetica Neue,sans-serif"
    end
  end

  private

  def embed_url
    Rails.application.routes.url_helpers.embed_subscribe_url(slug: slug)
  end
end
