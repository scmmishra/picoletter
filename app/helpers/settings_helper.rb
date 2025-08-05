module SettingsHelper
  def settings_nav_link(text, path, newsletter = nil)
    # Check authorization if newsletter is provided
    return "" if newsletter && !should_show_settings_link?(text.downcase, newsletter)

    css_classes = if current_page?(path)
      "text-stone-800"
    else
      "hover:text-stone-500"
    end

    link_to text, path, class: css_classes
  end

  private

  def should_show_settings_link?(link_name, newsletter)
    case link_name
    when "general"
      newsletter.can_access?(:general)
    when "sending domain"
      newsletter.can_access?(:sending)
    when "design"
      newsletter.can_access?(:design)
    when "usage & billing"
      newsletter.can_access?(:billing)
    when "embedding"
      newsletter.can_access?(:embedding)
    when "profile"
      true # Always accessible
    else
      true # Default to showing unknown links
    end
  end
end
