FactoryBot.define do
  factory(:user) do
    active { true }
    bio { Faker::Lorem.paragraph }
    email { Faker::Internet.unique.email } # Use unique email
    is_superadmin { false }
    password { Faker::Internet.password }
    name { Faker::Name.name }
    # Add verified_at for OAuth tests
    verified_at { nil } # Default to unverified

    trait :verified do
      verified_at { Time.current }
    end
  end
end
