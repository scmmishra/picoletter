FactoryBot.define do
  factory :email do
    bounced_at { nil }
    delivered_at { nil }
    email_id { "uuid-to-be-generated" }
    status { nil }
    subscriber_id { nil }

    post
  end
end
