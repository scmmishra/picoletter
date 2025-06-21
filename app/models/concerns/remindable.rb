module Remindable
  extend ActiveSupport::Concern

  included do
    scope :eligible_for_reminder, -> do
      joins(:newsletter)
        .where(status: "unverified")
        .where(newsletters: { auto_reminder_enabled: true })
        .where("subscribers.created_at <= ?", 24.hours.ago)
        .where("subscribers.additional_data->>'last_reminder_sent_at' IS NULL")
    end
  end

  def send_reminder
    SubscriptionMailer.with(subscriber: self).confirmation_reminder.deliver_later
  end

  def reminder_sent?
    additional_data["last_reminder_sent_at"].present?
  end

  def last_reminder_sent_at
    return nil unless additional_data["last_reminder_sent_at"]
    Time.zone.parse(additional_data["last_reminder_sent_at"])
  rescue ArgumentError
    nil
  end

  def record_reminder_sent!
    now = Time.current.iso8601
    update!(
      additional_data: additional_data.merge(
        "last_reminder_sent_at" => now,
        "reminders" => (additional_data["reminders"] || []) + [ now ]
      )
    )
  end

  def eligible_for_automatic_reminder?
    return false if verified? || unsubscribed?
    return false if reminder_sent?
    return false unless newsletter.auto_reminder_enabled?

    created_at <= 24.hours.ago
  end

  class_methods do
    def claim_for_reminder(subscriber_id)
      subscriber = find(subscriber_id)
      subscriber.with_lock do
        return unless subscriber.eligible_for_automatic_reminder?

        yield(subscriber) if block_given?
      end
    rescue ActiveRecord::RecordNotFound
      nil
    rescue StandardError => e
      RorVsWild.record_error(e, context: { subscriber_id: subscriber_id })
      nil
    end
  end
end
