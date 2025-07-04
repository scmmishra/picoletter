module SidebarHelper
  def sidebar_link(url:, label:, is_active: false, level: 1, count: nil, icon: nil, data: nil, target: nil)
    # Level-specific classes
    level_classes = if level == 2
      "text-stone-800 relative before:absolute before:left-2.5 before:top-0 before:w-px before:h-full before:bg-stone-300 last:before:h-4 after:absolute after:left-2.5 after:top-4 after:w-2 after:h-px after:bg-stone-300 after:hidden last:after:block"
    else
      ""
    end

    # Link classes
    link_classes = [
      "flex items-center justify-between gap-2",
      ("ml-4 my-0.5" if level == 2),
      "px-2 py-1.5 last:mb-0 rounded-md hover:bg-stone-200/40",
      ("bg-stone-200/50" if is_active)
    ].compact.join(" ")

    # Build link options
    link_options = { class: link_classes }
    link_options[:data] = data if data
    link_options[:target] = target if target

    content_tag :li, class: level_classes do
      link_to url, link_options do
        content = content_tag(:span, label)

        if count.present?
          content += content_tag(:span, count,
            class: "rounded-md px-2 py-0.5 leading-3 bg-stone-200 text-[10px] tabular-nums")
        elsif icon.present?
          content += lucide_icon(icon, class: "size-4")
        end

        content
      end
    end
  end
end
