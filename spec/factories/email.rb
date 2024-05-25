FactoryBot.define do
  factory :email do
    bounced_at { nil }
    delivered_at { nil }
    email_id { "uuid-to-be-generated" }
    post_id { 123 }
    status { nil }
    subscriber_id { nil }
  end
end
