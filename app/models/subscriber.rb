# == Schema Information
#
# Table name: subscribers
#
#  id                 :bigint           not null, primary key
#  additional_data    :jsonb            not null
#  analytics_data     :jsonb
#  created_via        :string
#  email              :string
#  full_name          :string
#  labels             :string           default([]), is an Array
#  notes              :text
#  reminder_status    :integer          default(0), not null
#  status             :integer          default("unverified")
#  unsubscribe_reason :string
#  unsubscribed_at    :datetime
#  verified_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  newsletter_id      :integer          not null
#
# Indexes
#
#  index_subscribers_on_additional_data   (additional_data) USING gin
#  index_subscribers_on_labels            (labels) USING gin
#  index_subscribers_on_newsletter_id     (newsletter_id)
#  index_subscribers_on_reminder_sent_at  (((additional_data ->> 'last_reminder_sent_at'::text)))
#  index_subscribers_on_reminder_status   (reminder_status)
#  index_subscribers_on_status            (status)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
class Subscriber < ApplicationRecord
  include Statusable

  taggable_array :labels

  generates_token_for :unsubscribe
  generates_token_for :confirmation, expires_in: 1.month

  belongs_to :newsletter
  has_many :emails, dependent: :destroy

  before_validation :normalize_labels
  before_save :filter_invalid_labels

  scope :verified, -> { where(status: "verified") }
  scope :unverified, -> { where(status: "unverified") }
  scope :unsubscribed, -> { where(status: "unsubscribed") }
  scope :subscribed, -> { verified.or(unverified) }

  scope :eligible_for_reminder, -> do
    includes(:newsletter)
      .joins(:newsletter)
      .where(status: "unverified")
      .where(newsletters: { auto_reminder_enabled: true })
      .where("subscribers.created_at <= ?", 24.hours.ago)
      .where("subscribers.additional_data->>'last_reminder_sent_at' IS NULL")
  end

  enum :status, { unverified: 0, verified: 1, unsubscribed: 2 }
  enum :unsubscribe_reason, { bounced: "bounced", complained: "complained", spam: "spam" }
  validates :email, presence: true, uniqueness: { case_sensitive: false, scope: :newsletter_id, message: "has already subscribed" }

  def verify!
    update(status: "verified", verified_at: Time.current)
  end

  def display_name
    full_name.presence || email
  end

  def unsubscribe!
    update(status: "unsubscribed", unsubscribed_at: Time.current)
  end

  def unsubscribe_with_reason!(reason)
    update(status: "unsubscribed", unsubscribed_at: Time.current, unsubscribe_reason: reason)
  end

  def send_reminder
    SubscriptionMailer.with(subscriber: self).confirmation_reminder.deliver_later
  end

  def send_confirmation_email
    SubscriptionMailer.with(subscriber: self).confirmation.deliver_later
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
    return false if additional_data["processing_reminder_at"].present?
    return false unless newsletter.auto_reminder_enabled?

    created_at <= 24.hours.ago
  end

  def self.claim_for_reminder(subscriber_id)
    subscriber = find(subscriber_id)
    subscriber.with_lock do
      return nil unless subscriber.eligible_for_automatic_reminder?

      # Mark as processing to prevent other jobs from claiming
      now = Time.current.iso8601
      subscriber.update!(
        additional_data: subscriber.additional_data.merge("processing_reminder_at" => now)
      )
      subscriber
    end
  rescue ActiveRecord::RecordNotFound
    nil
  rescue StandardError => e
    Rails.error.report(e, context: { subscriber_id: subscriber_id })
    nil
  end

  private

  def normalize_labels
    self.labels = labels.compact.map(&:downcase).uniq if labels.present?
  end

  def filter_invalid_labels
    return if labels.blank?
    valid_labels = newsletter.labels.pluck(:name)
    self.labels = labels & valid_labels # Keep only valid labels using array intersection
  end
end
