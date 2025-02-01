FactoryBot.define do
  factory(:post) do
    sequence(:title) { |n| "Title for the post #{n}" }
    sequence(:slug) { |n| "title-for-the-post-#{n}" }
    content { nil }
    published_at { nil }
    scheduled_at { nil }
    status { "draft" }
    newsletter
  end
end
