module Timezonable
  extend ActiveSupport::Concern

  def created_at_tz
    created_at.in_time_zone(newsletter_tz)
  end

  def updated_at_tz
    updated_at.in_time_zone(newsletter_tz)
  end

  def published_at_tz
    published_at.in_time_zone(newsletter_tz)
  end

  def scheduled_at_tz
    scheduled_at.in_time_zone(newsletter_tz)
  end

  private

  def newsletter_tz
    newsletter.timezone
  end
end
