# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  active          :boolean
#  additional_data :jsonb
#  bio             :text
#  email           :string           not null
#  is_superadmin   :boolean          default(FALSE)
#  limits          :jsonb
#  name            :string
#  password_digest :string
#  verified_at     :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_is_superadmin  (is_superadmin)
#
class User < ApplicationRecord
  include Billable

  has_secure_password :password, validations: true

  generates_token_for :verification, expires_in: 48.hours

  has_many :sessions, dependent: :destroy
  has_many :connected_services, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :newsletters, through: :memberships, source: :newsletter
  has_many :owned_newsletters, class_name: "Newsletter", foreign_key: :user_id
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id, dependent: :nullify

  has_many :subscribers, through: :newsletters
  has_many :posts, through: :newsletters
  has_many :emails, through: :posts
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :bio, length: { maximum: 500 }

  scope :active, -> { where(active: true) }
  before_create :activate_user
  after_create_commit :perform_after_create

  def super?
    self.is_superadmin
  end

  def verify!
    self.update(verified_at: Time.now)
  end

  def verified?
    verification_enabled = AppConfig.get("VERIFY_SIGNUPS", true)
    return true unless verification_enabled

    self.verified_at.present?
  end

  def send_verification_email
    UserMailer.with(user: self).verify_email.deliver_later
  end

  def send_verification_email_once
    key = "verification_email_#{self.id}"

    if !Rails.cache.fetch(key)
      self.send_verification_email
      Rails.cache.write(key, expires_in: 6.hours)
    end
  end

  def newsletter_role(newsletter)
    return :owner if newsletter.user_id == id
    memberships.find_by(newsletter: newsletter)&.role&.to_sym
  end

  private

  def perform_after_create
    response = self.init_customer if AppConfig.billing_enabled?
  rescue StandardError => e
    RorVsWild.record_error(e, context: { user: self.id, response: response })
    Rails.logger.error("Error creating customer for user #{self.id} with #{e.message}")
  end

  def activate_user
    self.active = true if self.active.nil?
    self.additional_data ||= {}
    self.limits ||= {}
  end
end
