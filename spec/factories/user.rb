FactoryBot.define do
  factory(:user) do
    active { true }
    bio { nil }
    email { "neo@example.com" }
    is_superadmin { true }
    password { "password" }
    name { "Neo Anderson" }
  end
end
