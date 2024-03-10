class User < ApplicationRecord
  has_secure_password :password, validations: true

  has_many :sessions, dependent: :destroy

  scope :active, -> { where(active: true) }
end
