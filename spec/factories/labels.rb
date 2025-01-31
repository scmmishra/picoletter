FactoryBot.define do
  factory :label do
    name { "MyString" }
    description { "MyText" }
    color { "MyString" }
    newsletter { nil }
  end
end
