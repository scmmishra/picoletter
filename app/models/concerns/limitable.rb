module Limitable
  extend ActiveSupport::Concern

  included do
    before_create :set_default_limits
  end

  def subscriber_limit
    return Float::INFINITY unless billing_enabled?
    self.limits&.dig("subscriber_limit") || AppConfig.get("DEFAULT_SUBSCRIBER_LIMIT", 100)
  end

  def monthly_email_limit
    return Float::INFINITY unless billing_enabled?
    self.limits&.dig("monthly_email_limit") || AppConfig.get("DEFAULT_MONTHLY_EMAIL_LIMIT", 1000)
  end

  def total_subscribers_count
    self.subscribers.verified.count
  end

  def approaching_subscriber_limit?
    return false unless billing_enabled?
    total = total_subscribers_count
    limit = subscriber_limit
    total >= (limit * 0.8) && total < limit
  end

  def reached_subscriber_limit?
    return false unless billing_enabled?
    total_subscribers_count >= subscriber_limit
  end

  def emails_sent_this_month
    start_date = Time.current.beginning_of_month
    end_date = Time.current.end_of_month
    self.emails.where(status: :sent, created_at: start_date..end_date).count
  end

  def emails_remaining_this_month
    return Float::INFINITY unless billing_enabled?
    [ monthly_email_limit - emails_sent_this_month, 0 ].max
  end

  def can_send_emails?(count = 1)
    return true unless billing_enabled?
    emails_sent_this_month + count <= monthly_email_limit * 1.2
  end

  def subscriber_limit_status
    return { status: :unlimited } unless billing_enabled?

    total = total_subscribers_count
    limit = subscriber_limit

    if total >= limit
      { status: :exceeded, count: total, limit: limit, percentage: 100 }
    elsif total >= (limit * 0.8)
      { status: :approaching, count: total, limit: limit, percentage: (total.to_f / limit * 100).round }
    else
      { status: :ok, count: total, limit: limit, percentage: (total.to_f / limit * 100).round }
    end
  end

  def email_limit_status
    return { status: :unlimited } unless billing_enabled?

    sent = emails_sent_this_month
    limit = monthly_email_limit

    if sent >= limit
      { status: :exceeded, sent: sent, limit: limit, percentage: 100 }
    elsif sent >= (limit * 0.8)
      { status: :approaching, sent: sent, limit: limit, percentage: (sent.to_f / limit * 100).round }
    else
      { status: :ok, sent: sent, limit: limit, percentage: (sent.to_f / limit * 100).round }
    end
  end

  private

  def set_default_limits
    return unless billing_enabled?

    self.limits = {
      subscriber_limit: AppConfig.get("DEFAULT_SUBSCRIBER_LIMIT", 1000),
      monthly_email_limit: AppConfig.get("DEFAULT_MONTHLY_EMAIL_LIMIT", 10000)
    } if self.limits.nil?
  end
end
