require "rails_helper"

RSpec.describe Cloudflare::CreateCustomHostnameService, type: :service do
  let(:newsletter) { create(:newsletter, slug: "demo-letter") }
  let(:publishing_domain) { create(:publishing_domain, newsletter: newsletter, hostname: "demo.example.com") }
  let(:service) { described_class.new(publishing_domain) }

  before do
    allow(AppConfig).to receive(:get).and_call_original
  end

  describe "#call" do
    context "when Cloudflare integration is disabled" do
      before do
        stub_cloudflare_env(token: nil, account_id: nil, zone_id: nil)
      end

      it "returns a failure result without mutating the record" do
        expect do
          result = service.call

          expect(result.success?).to be(false)
          expect(result.error).to eq(:cloudflare_disabled)
        end.not_to change { publishing_domain.reload.updated_at }
      end
    end

    context "when the API call succeeds" do
      before do
        stub_cloudflare_env
        allow(HTTParty).to receive(:post).and_return(api_response)
      end

      let(:api_response) do
        instance_double(
          HTTParty::Response,
          success?: true,
          parsed_response: {
            "result" => {
              "id" => "abc123",
              "hostname" => "demo.example.com",
              "ssl" => { "status" => "pending_validation" },
              "ownership_verification_http" => {
                "http_url" => "https://demo.example.com/.well-known/cf-custom-hostname-challenge/abc123",
                "http_body" => "verification-body"
              }
            }
          },
          code: 200
        )
      end

      it "updates the domain with Cloudflare identifiers and verification payload" do
        result = service.call

        publishing_domain.reload
        expect(publishing_domain.cloudflare_id).to eq("abc123")
        expect(publishing_domain.cloudflare_ssl_status).to eq("pending_validation")
        expect(publishing_domain.status).to eq("provisioning")
        expect(publishing_domain.verification_http_path).to eq("/.well-known/cf-custom-hostname-challenge/abc123")
        expect(publishing_domain.verification_http_body).to eq("verification-body")
        expect(publishing_domain.verification_method).to eq("http")

        expect(result.success?).to be(true)
        expect(result.data[:cloudflare_id]).to eq("abc123")
      end
    end

    context "when the API call fails" do
      before do
        stub_cloudflare_env
        allow(HTTParty).to receive(:post).and_return(api_response)
      end

      let(:api_response) do
        instance_double(
          HTTParty::Response,
          success?: false,
          parsed_response: {
            "errors" => [{ "message" => "Hostname already exists" }]
          },
          code: 409
        )
      end

      it "returns a failure result and records the error message" do
        result = service.call

        expect(result.success?).to be(false)
        expect(result.error).to eq(:api_error)
        expect(result.data[:http_status]).to eq(409)
        expect(publishing_domain.reload.last_error).to include("Hostname already exists")
        expect(publishing_domain.status).to eq("failed")
    end
  end
  end

  def stub_cloudflare_env(token: "api-token", account_id: "acct", zone_id: "zone")
    allow(AppConfig).to receive(:get).with("CLOUDFLARE_API_TOKEN", nil).and_return(token)
    allow(AppConfig).to receive(:get).with("CLOUDFLARE_ACCOUNT_ID", nil).and_return(account_id)
    allow(AppConfig).to receive(:get).with("CLOUDFLARE_ZONE_ID", nil).and_return(zone_id)
  end
end
