module Themeable
  extend ActiveSupport::Concern

  ThemeConfig = Struct.new(:name, :primary, :text_on_primary, :primary_hover, :tint, keyword_init: true)

  included do
    # add a class method to get the theme config
    def self.theme_config
      # load colors from conifg/colors.yml
      data = YAML.load_file(Rails.root.join("config", "colors.yml"))
      data.map { |item| ThemeConfig.new(item) }
    end

    def self.available_icons
      %w[academic-cap arrow-trending-up at-symbol backspace banknotes battery-50 battery-100 beaker bell-snooze bolt book-open bookmark briefcase bug-ant building-library building-office cake calculator calendar-date-range camera chart-bar chart-pie chat-bubble-bottom-center-text check-badge circle-stack clipboard-document-check clipboard clock cloud code-bracket cog-8-tooth command-line computer-desktop cpu-chip credit-card cube-transparent cube cursor-arrow-rays cursor-arrow-ripple device-phone-mobile device-tablet envelope-open envelope eye-dropper eye face-frown face-smile film finger-print fire flag folder gift globe-americas hand-raised hand-thumb-down hand-thumb-up heart home-modern identification inbox key language lifebuoy light-bulb map-pin megaphone microphone moon musical-note phone photo presentation-chart-bar presentation-chart-line printer puzzle-piece qr-code radio rectangle-group rectangle-stack rocket-launch scale scissors server-stack shield-check shield-exclamation shopping-bag shopping-cart signal sparkles square-2-stack square-3-stack-3d swatch tag ticket trash trophy truck tv user-group variable video-camera viewfinder-circle wallet wifi window wrench-screwdriver]
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
