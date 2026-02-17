# == Schema Information
#
# Table name: connected_services
#
#  id         :bigint           not null, primary key
#  provider   :string           not null
#  uid        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_connected_services_on_provider_and_uid  (provider,uid) UNIQUE
#  index_connected_services_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ConnectedService < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true
  validates :provider, uniqueness: { scope: :uid }

  scope :google, -> { where(provider: "google_oauth2") }
  scope :github, -> { where(provider: "github") }

  def self.find_or_create_from_auth_hash(auth_hash, user = nil)
    service = find_or_initialize_by(provider: auth_hash["provider"], uid: auth_hash["uid"])
    return service unless service.new_record?

    user ||= find_or_create_user_from_auth(auth_hash)
    service.update!(user: user)
    service
  end

  def self.find_or_create_user_from_auth(auth_hash)
    email = auth_hash.dig("info", "email")
    return nil if email.blank?

    User.find_by(email: email) || create_user_from_auth!(auth_hash)
  end

  def self.create_user_from_auth!(auth_hash)
    raise Exceptions::InviteCodeRequiredError, "Invite code required for new account creation" if AppConfig.get("INVITE_CODE").present?

    info = auth_hash["info"]
    password = SecureRandom.hex(24)

    User.create!(
      email: info["email"],
      name: info["name"] || info["email"].split("@").first,
      password: password,
      password_confirmation: password
    )
  end

  private_class_method :find_or_create_user_from_auth, :create_user_from_auth!
end
