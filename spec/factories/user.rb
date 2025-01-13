FactoryBot.define do
  factory(:user) do
    active { true }
    bio { nil }
    email { "neo@example.com" }
    is_superadmin { true }
    password { "password" }
    name { "Neo Anderson" }

    trait :inactive do
      active { false }
    end

    trait :with_bio do
      bio { "This is a sample bio." }
    end

    trait :admin do
      is_superadmin { true }
    end

    trait :non_admin do
      is_superadmin { false }
    end

    trait :with_custom_email do
      transient do
        custom_email { "custom@example.com" }
      end

      email { custom_email }
    end
  end
end
