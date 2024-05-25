FactoryBot.define do
  factory(:post) do
    content { nil }
    published_at { nil }
    scheduled_at { nil }
    slug { "title-for-the-post" }
    status { "draft" }
    title { "Title for the post" }

    newsletter
  end
end
