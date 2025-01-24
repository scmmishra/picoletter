FactoryBot.define do
  factory(:user) do
    bio { Faker::Lorem.paragraph }
    email { Faker::Internet.email }
    is_superadmin { true }
    password { Faker::Internet.password }
    name { Faker::Name.name }
  end
end
