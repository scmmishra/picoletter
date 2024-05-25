FactoryBot.define do
  factory :subscriber do
    newsletter
    email { Faker::Internet.email }
  end

  factory :email do
    post
  end
end
