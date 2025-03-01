FactoryBot.define do
  factory(:user) do
    active { true }
    bio { Faker::Lorem.paragraph }
    email { Faker::Internet.email }
    is_superadmin { false }
    password { Faker::Internet.password }
    name { Faker::Name.name }
  end
end
