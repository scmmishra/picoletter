require "rails_helper"

RSpec.describe "Public host resolution", type: :request do
  before do
    allow(AppConfig).to receive(:platform_publishing_domain).and_return("picoletter.page")
  end

  describe "platform subdomains" do
    let!(:newsletter) { create(:newsletter, title: "Demo", slug: "demo") }
    let!(:post) do
      create(
        :post,
        newsletter: newsletter,
        status: "published",
        published_at: Time.current
      ).tap { |post| post.update!(content: "<div>Test body</div>") }
    end

    it "renders the newsletter homepage when accessed via the platform hostname" do
      host! "demo.picoletter.page"

      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Demo")
    end

    it "renders the newsletter archive when accessed via the platform hostname" do
      host! "demo.picoletter.page"

      get "/posts"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("All posts")
      expect(response.body).to include(post.title)
    end

    it "renders a published post when accessed via the platform hostname" do
      host! "demo.picoletter.page"

      get "/posts/#{post.slug}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(post.title)
    end
  end

  describe "custom domains" do
    let!(:newsletter) { create(:newsletter, title: "Custom Demo", slug: "custom-demo") }
    let!(:publishing_domain) do
      create(:publishing_domain, newsletter: newsletter, hostname: "news.example.com", status: :active)
    end

    it "renders the newsletter homepage when accessed via the custom hostname" do
      host! "news.example.com"

      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Custom Demo")
    end

    it "returns not found for inactive domains" do
      publishing_domain.update!(status: :pending)

      host! "news.example.com"

      get "/"

      expect(response).to have_http_status(:not_found)
    end
  end

end
