# frozen_string_literal: true

class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(method, options = {})
    labelled_field(method, options) do
      super(method, default_options(options))
    end
  end

  def url_field(method, options = {})
    labelled_field(method, options) do
      super(method, default_options(options))
    end
  end

  def email_field(method, options = {})
    labelled_field(method, options) do
      super(method, default_options(options))
    end
  end

  def password_field(method, options = {})
    labelled_field(method, options) do
      super(method, default_options(options))
    end
  end

  def text_area(method, options = {})
    labelled_field(method, options) do
      super(method, default_options(options))
    end
  end

  def select(method, choices, options = {}, html_options = {})
    labelled_field(method, options) do
      super(method, choices, options, default_options(html_options))
    end
  end

  private

  def labelled_field(method, options, &block)
    label_text = options.delete(:label) || method.to_s.humanize
    @template.content_tag(:div, class: "space-y-1") do
      label(method, label_text, class: "ml-px text-sm text-stone-500 font-sans") +
        block.call +
        hint_tag(options[:hint])
    end
  end

  def hint_tag(hint)
    return "" unless hint

    @template.content_tag(:div, hint.html_safe, class: "font-sans text-xs text-stone-400")
  end

  def default_options(options)
    field_options = { class: "input w-full" }
    field_options[:class] += " block" if options[:block]
    field_options[:class] += " #{options[:class]}" if options[:class]
    options.except(:hint, :label, :class).merge(field_options)
  end
end
