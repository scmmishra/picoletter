# == Schema Information
#
# Table name: invitations
#
#  id            :bigint           not null, primary key
#  accepted_at   :datetime
#  email         :string           not null
#  role          :string           default("editor"), not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  invited_by_id :bigint           not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_invitations_on_invited_by_id  (invited_by_id)
#  index_invitations_on_newsletter_id  (newsletter_id)
#  index_invitations_on_token          (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (invited_by_id => users.id)
#  fk_rails_...  (newsletter_id => newsletters.id)
#
class Invitation < ApplicationRecord
  EXPIRATION_PERIOD = 14.days
  belongs_to :newsletter
  belongs_to :invited_by, class_name: "User"

  enum :role, {
    administrator: "administrator",
    editor: "editor"
  }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create
  before_validation :normalize_email
  scope :pending, -> { where(accepted_at: nil).where(created_at: EXPIRATION_PERIOD.ago..) }
  scope :expired, -> { where(accepted_at: nil).where(created_at: ...EXPIRATION_PERIOD.ago) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :for_email, ->(value) do
    normalized_email = value.to_s.strip.downcase
    normalized_email.present? ? where("LOWER(email) = ?", normalized_email) : none
  end

  def pending?
    accepted_at.nil? && !expired?
  end

  def expired?
    return false if created_at.blank?

    expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(user)
    return false if accepted? || expired?

    transaction do
      membership = newsletter.memberships.find_or_create_by!(user: user) do |record|
        record.role = role
      end

      membership.update!(role: role) if membership.role != role

      update!(accepted_at: Time.current)
    end
  end

  def expires_at
    return nil if created_at.blank?

    created_at + EXPIRATION_PERIOD
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64(16)
  end
end
