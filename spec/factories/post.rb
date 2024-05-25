FactoryBot.define do
  factory(:post) do
    content { nil }
    newsletter_id { 16 }
    published_at { nil }
    scheduled_at { nil }
    slug { "title-for-the-post" }
    status { "draft" }
    title { "Title for the post" }
  end
end
