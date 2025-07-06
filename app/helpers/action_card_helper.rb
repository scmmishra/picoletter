module ActionCardHelper
  def action_card(title:, help_text:, &block)
    content_tag :div, class: "flex gap-2 justify-between" do
      content_tag(:div) do
        content_tag(:h3, title, class: "text-base font-medium text-stone-800") +
        content_tag(:p, help_text, class: "mt-1 text-sm text-stone-600")
      end +
      content_tag(:div, class: "w-[140px] flex-shrink-0") do
        capture(&block) if block_given?
      end
    end
  end

  def post_action_card(title:, description:, layout: :stacked, &block)
    content_tag :div, class: "border border-stone-200 bg-stone-100 rounded-2xl p-5 -mx-5 font-sans #{'flex gap-5' if layout == :inline}" do
      if layout == :inline
        # Inline layout: title/description on left, action on right (like delete)
        content_tag(:div, class: "flex-grow") do
          content_tag(:h3, title, class: "text-lg font-semibold text-stone-800 -mt-0.5") +
          content_tag(:p, description, class: "text-stone-500")
        end +
        content_tag(:div, class: "flex-shrink-0") do
          capture(&block) if block_given?
        end
      else
        # Stacked layout: title/description on top, action below (like schedule/cohort)
        content_tag(:h3, title, class: "text-lg font-semibold text-stone-800 -mt-0.5") +
        content_tag(:p, description, class: "text-stone-500") +
        if block_given?
          content_tag(:div, class: "mt-4") do
            capture(&block)
          end
        else
          "".html_safe
        end
      end
    end
  end
end
