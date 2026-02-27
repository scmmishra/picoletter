module ApplicationHelper
  include Pagy::Frontend

  def labeled_form_with(**options, &block)
    # Extract permission and check if form should be readonly
    permission = options.delete(:permission)
    if permission && @newsletter
      options[:readonly] = !@newsletter.can_write?(permission)
    end

    options[:builder] = LabellingFormBuilder
    form_with(**options, &block)
  end

  def highlight_email_code_blocks(content)
    return content if content.blank?
    return content unless rouge_available?

    fragment = Nokogiri::HTML::DocumentFragment.parse(content.to_s)
    formatter = Rouge::Formatters::HTMLInline.new(Rouge::Themes::Github.new)

    fragment.css("pre[data-language]").each do |pre_node|
      code = extract_code_text(pre_node)
      language = pre_node["data-language"].to_s
      lexer = Rouge::Lexer.find_fancy(language, code) || Rouge::Lexers::PlainText
      pre_node.inner_html = formatter.format(lexer.lex(code))
    rescue StandardError => error
      Rails.logger.warn("Email syntax highlighting skipped for one block: #{error.class} - #{error.message}")
    end

    fragment.to_html.html_safe
  rescue StandardError => error
    Rails.logger.warn("Email syntax highlighting failed: #{error.class} - #{error.message}")
    content
  end

  private

  def rouge_available?
    return true if defined?(Rouge)

    require "rouge"
    true
  rescue LoadError
    false
  end

  def extract_code_text(pre_node)
    code_fragment = Nokogiri::HTML::DocumentFragment.parse(pre_node.inner_html.to_s)
    code_fragment.css("br").each { |node| node.replace("\n") }
    code_fragment.text
  end
end
