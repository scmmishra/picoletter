module ActionCardHelper
  def action_card(title:, help_text:, &block)
    content_tag :div, class: "flex gap-2 justify-between" do
      content_tag(:div) do
        content_tag(:h3, title, class: "text-lg font-medium text-stone-800") +
        content_tag(:p, help_text, class: "mt-1 text-sm text-stone-600")
      end +
      content_tag(:div, class: "w-[140px] flex-shrink-0") do
        capture(&block) if block_given?
      end
    end
  end
end