module Limitable
  extend ActiveSupport::Concern

  DEFAULT_LIMITS = {
    newsletters: 5,
    emails: 1000
  }

  included do
    after_initialize :set_default_limits
  end

  def set_default_limits
    self.limits ||= DEFAULT_LIMITS
  end

  def update_limit(key, value)
    self.limits[key.to_sym] = value
    self.save
  end

  def limit(key)
    self.limits[key.to_sym]
  end

  def exceeded?(key)
    limit = self.limit(key)
    return false if limit.nil?
    return false if limit[:limit].nil?

    if key == :emails
      self.emails_sent_this_month >= limit[:limit]
    elsif key == :newsletters
      self.newsletters.count >= limit[:limit]
    end
  end

  def emails_sent_this_month
    start_date = Time.current.beginning_of_month
    end_date = Time.current.end_of_month
    emails.where(created_at: start_date..end_date).count
  end
end
