# == Schema Information
#
# Table name: subscribers
#
#  id                 :bigint           not null, primary key
#  analytics_data     :jsonb
#  created_via        :string
#  email              :string
#  full_name          :string
#  labels             :string           default([]), is an Array
#  notes              :text
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
#  index_subscribers_on_labels         (labels) USING gin
#  index_subscribers_on_newsletter_id  (newsletter_id)
#  index_subscribers_on_status         (status)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
class Subscriber < ApplicationRecord
  include Statusable

  taggable_array :labels

  generates_token_for :unsubscribe
  generates_token_for :confirmation, expires_in: 48.hours

  belongs_to :newsletter
  has_many :emails, dependent: :destroy
  has_many :reminders, class_name: "SubscriberReminder", dependent: :destroy

  before_validation :normalize_labels
  before_save :filter_invalid_labels

  scope :verified, -> { where(status: "verified") }
  scope :unverified, -> { where(status: "unverified") }
  scope :unsubscribed, -> { where(status: "unsubscribed") }
  scope :subscribed, -> { verified.or(unverified) }
  scope :eligible_for_auto_reminder, -> {
    unverified
      .where(created_at: (24.hours.ago - 30.minutes)..(24.hours.ago + 30.minutes))
      .left_joins(:reminders)
      .where(subscriber_reminders: { id: nil })
  }

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

  def send_reminder(kind: :manual)
    SendSubscriberReminderJob.perform_later(id, kind: kind)
  end

  def send_confirmation_email
    SubscriptionMailer.with(subscriber: self).confirmation.deliver_later
  end

  def has_delivery_issues?
    emails.where(status: [ :bounced, :complained ]).exists?
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
