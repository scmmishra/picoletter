FactoryBot.define do
  factory(:newsletter) do
    description { Faker::Lorem.sentence }
    domain_id { Faker::Internet.uuid }
    reply_to { Faker::Internet.email }
    sending_address { Faker::Internet.email }
    status { nil }
    template { nil }
    title { Faker::Company.name }
    website { nil }

    user

    trait :with_ready_ses_tenant do
      after(:create) do |newsletter|
        create(:ses_tenant, newsletter: newsletter, status: :ready)
      end
    end

    trait :with_pending_ses_tenant do
      after(:create) do |newsletter|
        create(:ses_tenant, :pending, newsletter: newsletter)
      end
    end
  end
end
