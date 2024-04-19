module ClipboardHelper
  def button_to_copy_to_clipboard(value, &block)
    button_class = "uppercase text-xs px-1 py-0.5 border border-stone-200 bg-white rounded-lg text-stone-600"
    button_data = {
      controller: "copy-to-clipboard",
      action: "copy-to-clipboard#copy",
      copy_to_clipboard_content_value: value
    }

    copy_default = tag.svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 16 16", fill: "currentColor", class: "size-3 default-icon text-stone-400") do
      concat tag.path("fill-rule": "evenodd", d: "M11.986 3H12a2 2 0 0 1 2 2v6a2 2 0 0 1-1.5 1.937v-2.523a2.5 2.5 0 0 0-.732-1.768L8.354 5.232A2.5 2.5 0 0 0 6.586 4.5H4.063A2 2 0 0 1 6 3h.014A2.25 2.25 0 0 1 8.25 1h1.5a2.25 2.25 0 0 1 2.236 2ZM10.5 4v-.75a.75.75 0 0 0-.75-.75h-1.5a.75.75 0 0 0-.75.75V4h3Z", "clip-rule": "evenodd")
      concat tag.path(d: "M3 6a1 1 0 0 0-1 1v7a1 1 0 0 0 1 1h7a1 1 0 0 0 1-1v-3.586a1 1 0 0 0-.293-.707L7.293 6.293A1 1 0 0 0 6.586 6H3Z")
    end

    copy_success = tag.svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 16 16", fill: "currentColor", class: "hidden text-stone-800 size-3 success-icon") do
      concat tag.path("fill-rule": "evenodd", d: "M11.986 3H12a2 2 0 0 1 2 2v6a2 2 0 0 1-1.5 1.937V7A2.5 2.5 0 0 0 10 4.5H4.063A2 2 0 0 1 6 3h.014A2.25 2.25 0 0 1 8.25 1h1.5a2.25 2.25 0 0 1 2.236 2ZM10.5 4v-.75a.75.75 0 0 0-.75-.75h-1.5a.75.75 0 0 0-.75.75V4h3Z", "clip-rule": "evenodd")
      concat tag.path("fill-rule": "evenodd", d: "M2 7a1 1 0 0 1 1-1h7a1 1 0 0 1 1 1v7a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V7Zm6.585 1.08a.75.75 0 0 1 .336 1.005l-1.75 3.5a.75.75 0 0 1-1.16.234l-1.75-1.5a.75.75 0 0 1 .977-1.139l1.02.875 1.321-2.64a.75.75 0 0 1 1.006-.336Z", "clip-rule": "evenodd")
    end

    button_content = tag.div(class: "flex items-center gap-1") do
      concat copy_default
      concat copy_success

      if block_given?
        concat capture(&block)
      else
        concat tag.span("Copy to clipboard", class: "inline text-[10px]")
      end
    end

    tag.button(button_content, class: button_class, data: button_data)
  end
end
