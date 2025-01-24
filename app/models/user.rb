# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  additional_data :jsonb
#  bio             :text
#  blocked_at      :datetime
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
  include Tokenable

  has_secure_password :password, validations: true
  generates_token_for :verification, expires_in: 7.days

  has_many :sessions, dependent: :destroy
  has_many :newsletters, dependent: :destroy

  has_many :subscribers, through: :newsletters
  has_many :posts, through: :newsletters
  has_many :emails, through: :posts

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :bio, length: { maximum: 500 }

  scope :active, -> { where(blocked_at: nil) }

  def super?
    self.is_superadmin
  end

  def verified?
    self.verified_at.present?
  end

  def verify!
    update(verified_at: Time.current)
  end

  def blocked?
    blocked_at.present?
  end

  def block!
    update(blocked_at: Time.current)
  end

  def send_verification_email
    UserMailer.verify(self).deliver_later
  end

  private

  def activate_user
    self.blocked_at = nil
  end
end
