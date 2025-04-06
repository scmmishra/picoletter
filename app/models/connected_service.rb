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

    if service.new_record?
      # If no user is provided but we have an email, try to find a matching user
      if user.nil? && auth_hash["info"]&.key?("email")
        user = User.find_by(email: auth_hash["info"]["email"])

        # If we still don't have a user, create one
        if user.nil?
          user = User.new(
            email: auth_hash["info"]["email"],
            name: auth_hash["info"]["name"] || auth_hash["info"]["email"].split("@").first,
            password: SecureRandom.hex(24),
            password_confirmation: SecureRandom.hex(24)
          )
          user.save!
        end
      end

      service.user = user
      service.save!
    end

    service
  end
end
