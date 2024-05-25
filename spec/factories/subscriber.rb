FactoryBot.define do
  factory(:subscriber) do
    email { "subscriber@example.com" }
    full_name { "Subscriber Name" }
    newsletter
  end
end
