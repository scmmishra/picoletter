FactoryBot.define do
  factory :connected_service do
    provider { ["google_oauth2", "github"].sample }
    uid { SecureRandom.hex(10) }
    association :user
  end
end
