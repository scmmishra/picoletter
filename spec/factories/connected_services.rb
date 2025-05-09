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
FactoryBot.define do
  factory :connected_service do
    provider { [ "google_oauth2", "github" ].sample }
    uid { SecureRandom.hex(10) }
    association :user
  end
end
