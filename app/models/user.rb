# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  active          :boolean
#  bio             :text
#  email           :string           not null
#  is_superadmin   :boolean          default(FALSE)
#  limits          :jsonb
#  name            :string
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_is_superadmin  (is_superadmin)
#
class User < ApplicationRecord
  has_secure_password :password, validations: true

  has_many :sessions, dependent: :destroy
  has_many :newsletters, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :bio, length: { maximum: 500 }

  scope :active, -> { where(active: true) }
  before_create :activate_user
  before_create :set_basic_limits

  def self.default_limits
    {
      subscribers: 1000,
      emails: 10000
    }
  end

  def super?
    self.is_superadmin
  end

  def limits
    if AppConfig.get("ENABLE_BILLING", false)
      self[:limits] || self.class.default_limits
    else
      {
        subscribers: Float::INFINITY,
        emails: Float::INFINITY
      }
    end
  end

  private

  def activate_user
    self.active = true if self.active.nil?
  end

  def set_basic_limits
    return unless AppConfig.get("ENABLE_BILLING", false)
    self.limits = self.class.default_limits
  end
end
