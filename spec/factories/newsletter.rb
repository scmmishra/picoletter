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
  end
end
