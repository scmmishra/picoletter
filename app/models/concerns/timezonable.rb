module Timezonable
  extend ActiveSupport::Concern

  TIMEZONE_FIELDS = %i[created_at updated_at published_at scheduled_at].freeze

  TIMEZONE_FIELDS.each do |field|
    define_method("#{field}_tz") do
      send(field)&.in_time_zone(newsletter_tz)
    end
  end

  private

  def newsletter_tz
    newsletter.timezone
  end
end
