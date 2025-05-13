# frozen_string_literal: true

class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options = {})
    labelled_field(attribute, options) do
      super(attribute, default_field_options(options))
    end
  end

  def text_area(attribute, options = {})
    labelled_field(attribute, options) do
      super(attribute, default_field_options(options))
    end
  end

  def email_field(attribute, options = {})
    labelled_field(attribute, options) do
      super(attribute, default_field_options(options))
    end
  end

  def password_field(attribute, options = {})
    labelled_field(attribute, options) do
      super(attribute, default_field_options(options))
    end
  end

  private

  def default_field_options(options)
    field_options = { class: "input w-full" }
    field_options[:class] = "#{field_options[:class]} block" if options[:block]
    options.except(:hint).merge(field_options)
  end

  def labelled_field(attribute, options, &block)
    @template.content_tag(:div, class: "space-y-1") do
      label_tag = label(attribute, class: "ml-px text-sm text-stone-500 font-sans")
      input_tag = block_given? ? block.call : ""
      hint_tag = build_hint(options[:hint])

      label_tag + input_tag + hint_tag
    end
  end

  def build_hint(hint)
    return "" unless hint.present?

    @template.content_tag(:div, hint.html_safe, class: "font-sans text-xs text-stone-400")
  end
end
