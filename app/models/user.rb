# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  active          :boolean
#  bio             :text
#  email           :string           not null
#  name            :string
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class User < ApplicationRecord
  has_secure_password :password, validations: true

  has_many :sessions, dependent: :destroy
  has_many :newsletters, dependent: :destroy

  scope :active, -> { where(active: true) }
end
