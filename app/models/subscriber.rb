# == Schema Information
#
# Table name: subscribers
#
#  id                 :integer          not null, primary key
#  created_via        :string
#  email              :string
#  full_name          :string
#  status             :integer          default("unverified")
#  unsubscribed_at    :datetime
#  verification_token :string
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
#  newsletter_id  (newsletter_id => newsletters.id)
#
class Subscriber < ApplicationRecord
  belongs_to :newsletter

  scope :verified, -> { where(status: "verified") }
  scope :unverified, -> { where(status: "unverified") }
  scope :unsubscribed, -> { where(status: "unsubscribed") }
  scope :subscribed, -> { verified.or(unverified) }

  enum status: { unverified: 0, verified: 1, unsubscribed: 2 }

  before_create :generate_verification_token

  def verify!
    update(status: "verified", verified_at: Time.current)
  end

  def unsubscribe!
    update(status: "unsubscribed", unsubscribed_at: Time.current)
  end

  def generate_verification_token
    self.verification_token = SecureRandom.urlsafe_base64
    self.verification_token = verification_token.first(24)
  end

  def generate_unsubscribe_token
    payload = {
      sub: id,
      newsletter: newsletter.id,
      iat: Time.current.to_i
    }

    JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")
  end

  def send_confirmation_email
    # Send confirmation email
  end
end
