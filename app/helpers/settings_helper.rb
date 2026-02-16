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
      newsletter.can_read?(:general)
    when "sending domain"
      newsletter.can_read?(:sending)
    when "design"
      newsletter.can_read?(:design)
    when "team"
      newsletter.can_read?(:team)
    when "usage & billing"
      newsletter.can_read?(:billing)
    when "embedding"
      newsletter.can_read?(:embedding)
    when "api"
      newsletter.can_write?(:general)
    when "profile"
      newsletter.can_read?(:profile)
    else
      true # Default to showing unknown links
    end
  end
end
