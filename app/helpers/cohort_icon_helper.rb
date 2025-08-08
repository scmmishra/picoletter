module CohortIconHelper
  def cohort_icon(icon: "users", color: nil, size: "sm")
    # Size mappings
    size_classes = {
      "xs" => { container: "w-3 h-3 rounded", svg: "w-2 h-2" },
      "sm" => { container: "w-4 h-4 rounded", svg: "w-2.5 h-2.5" },
      "md" => { container: "w-5 h-5 rounded-md", svg: "w-3 h-3" },
      "lg" => { container: "w-8 h-8 rounded-lg", svg: "w-5 h-5" },
      "xl" => { container: "w-10 h-10 rounded-lg", svg: "w-6 h-6" }
    }

    # Get size classes
    container_class = size_classes[size][:container]
    svg_class = size_classes[size][:svg]

    # Resolve colors from theme config
    if color.present?
      theme = Newsletter.theme_config.find { |t| t.primary == color }
      primary_color = color
      tint_color = theme&.tint || "#{color}20"
    else
      # Default to Blue theme
      default_theme = Newsletter.theme_config.find { |t| t.name == "Blue" }
      primary_color = default_theme&.primary || "#3B82F6"
      tint_color = default_theme&.tint || "#EFF6FF"
    end

    content_tag :div,
      class: "#{container_class} flex items-center justify-center flex-shrink-0",
      style: "background-color: #{primary_color};" do
      content_tag :svg,
        class: svg_class,
        style: "color: #{tint_color}" do
        content_tag :use, "", href: "##{icon}"
      end
    end
  end
end
