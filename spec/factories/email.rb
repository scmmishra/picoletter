FactoryBot.define do
  factory :subscriber do
    newsletter
    email { Faker::Internet.email }
    status { :verified }
    unsubscribed_at { nil }
    unsubscribe_reason { nil }

    trait :unsubscribed do
      status { :unsubscribed }
      unsubscribed_at { Time.current }
    end

    trait :bounced do
      status { :unsubscribed }
      unsubscribed_at { Time.current }
      unsubscribe_reason { :bounced }
    end

    trait :complained do
      status { :unsubscribed }
      unsubscribed_at { Time.current }
      unsubscribe_reason { :complained }
    end
  end

  factory :email do
    post
    subscriber
    sequence(:id) { |n| "message-#{n}" }  # AWS SES message ID format
    status { :sent }
    delivered_at { nil }
    opened_at { nil }
    bounced_at { nil }
    complained_at { nil }

    trait :delivered do
      status { :delivered }
      delivered_at { Time.current }
    end

    trait :bounced do
      status { :bounced }
      bounced_at { Time.current }
    end

    trait :complained do
      status { :complained }
      complained_at { Time.current }
    end
  end
end
