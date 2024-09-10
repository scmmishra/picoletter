# == Schema Information
#
# Table name: subscribers
#
#  id                 :bigint           not null, primary key
#  created_via        :string
#  email              :string
#  full_name          :string
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
#  index_subscribers_on_newsletter_id  (newsletter_id)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
class Subscriber < ApplicationRecord
  include Tokenable
  include Statusable

  tokenable_on :unsubscribe
  tokenable_on :confirmation, expiry: 48.hours

  belongs_to :newsletter
  has_many :emails, dependent: :destroy

  scope :verified, -> { where(status: "verified") }
  scope :unverified, -> { where(status: "unverified") }
  scope :unsubscribed, -> { where(status: "unsubscribed") }
  scope :subscribed, -> { verified.or(unverified) }

  enum status: { unverified: 0, verified: 1, unsubscribed: 2 }
  enum unsubscribe_reason: { bounced: "bounced", complained: "complained" }
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

  def send_reminder
    SubscriptionMailer.with(subscriber: self).confirmation_reminder.deliver_later
  end

  def send_confirmation_email
    SubscriptionMailer.with(subscriber: self).confirmation.deliver_now
  end
end
