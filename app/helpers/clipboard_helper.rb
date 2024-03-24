module ClipboardHelper
  def button_to_copy_to_clipboard(value, &)
    tag.button class: "uppercase text-xs px-1 py-0.5 border border-stone-200 bg-white rounded-lg", data: {
      controller: "copy-to-clipboard", action: "copy-to-clipboard#copy",
      copy_to_clipboard_content_value: value
    }, &
  end
end
