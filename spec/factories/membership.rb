FactoryBot.define do
  factory :membership do
    user
    newsletter
    role { :administrator }

    trait :administrator do
      role { :administrator }
    end

    trait :editor do
      role { :editor }
    end
  end
end
