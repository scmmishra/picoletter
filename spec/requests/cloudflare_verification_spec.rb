require "rails_helper"

RSpec.describe "Cloudflare HTTP verification", type: :request do
  describe "GET /.well-known/cf-custom-hostname-challenge/:token" do
    let(:newsletter) { create(:newsletter, slug: "demo-letter") }
    let(:hostname) { "custom.example.com" }
    let!(:publishing_domain) do
      create(
        :publishing_domain,
        newsletter: newsletter,
        hostname: hostname,
        verification_http_path: "/.well-known/cf-custom-hostname-challenge/#{token}",
        verification_http_body: "challenge-body"
      )
    end
    let(:token) { "abc123" }

    before { host! hostname }

    it "returns the verification body as plain text" do
      get "/.well-known/cf-custom-hostname-challenge/#{token}"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to eq("challenge-body")
    end

    it "returns 404 when the token does not match" do
      get "/.well-known/cf-custom-hostname-challenge/other-token"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when no verification payload exists" do
      publishing_domain.update!(verification_http_body: nil)

      get "/.well-known/cf-custom-hostname-challenge/#{token}"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when no publishing domain matches the host" do
      host! "missing.example.com"

      get "/.well-known/cf-custom-hostname-challenge/#{token}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
