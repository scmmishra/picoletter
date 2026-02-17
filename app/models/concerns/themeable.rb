module Themeable
  extend ActiveSupport::Concern

  ThemeConfig = Struct.new(:name, :primary, :text_on_primary, :primary_hover, keyword_init: true)

  THEME_CONFIGS = YAML.load_file(Rails.root.join("config", "colors.yml")).map { |item| ThemeConfig.new(item) }.freeze

  FONT_MAP = {
    "serif"      => { css_class: "font-serif", family: "Georgia, ui-serif, Cambria, Times New Roman, Times, serif" },
    "sans-serif" => { css_class: "font-sans",  family: "SF Pro Display,-apple-system,BlinkMacSystemFont,Helvetica Neue,sans-serif" },
    "monospace"  => { css_class: "font-mono",  family: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, Liberation Mono, Courier New, monospace" }
  }.freeze

  included do
    def self.theme_config
      THEME_CONFIGS
    end
  end

  def font_class
    FONT_MAP.dig(font_preference, :css_class) || "font-serif"
  end

  def font_family
    FONT_MAP.dig(font_preference, :family) || FONT_MAP["sans-serif"][:family]
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
