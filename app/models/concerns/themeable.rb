module Themeable
  extend ActiveSupport::Concern

  ThemeConfig = Struct.new(:name, :primary, :text_on_primary, :primary_hover, keyword_init: true)

  THEME_CONFIGS = YAML.load_file(Rails.root.join("config", "colors.yml")).map { |item| ThemeConfig.new(item) }.freeze

  included do
    def self.theme_config
      THEME_CONFIGS
    end
  end

  def font_class
    case font_preference
    when "serif"
      "font-serif"
    when "sans-serif"
      "font-sans"
    when "monospace"
      "font-mono"
    else
      "font-serif"
    end
  end


  def theme
    # find theme config matching newsletter primary color
    # default primary #09090b
    primary = primary_color || "#09090B"
    Newsletter.theme_config.find { |config| config.primary.upcase == primary.upcase }
  end

  def primary_styles
    primary = "--pl-primary-color: #{theme.primary};"
    hover = "--pl-primary-hover-color: #{theme.primary_hover};"
    text = "--pl-primary-text-color:  #{theme.text_on_primary};"

    "#{primary} #{text} #{hover}"
  end
end
