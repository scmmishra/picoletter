require "rails_helper"

RSpec.describe Cloudflare::CheckCustomHostnameService, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:newsletter) { create(:newsletter, slug: "demo-letter") }
  let(:publishing_domain) do
    create(
      :publishing_domain,
      newsletter: newsletter,
      hostname: "demo.example.com",
      cloudflare_id: "abc123",
      status: :provisioning
    )
  end
  let(:service) { described_class.new(publishing_domain) }

  before do
    allow(AppConfig).to receive(:get).and_call_original
  end

  after { travel_back }

  describe "#call" do
    context "when Cloudflare integration is disabled" do
      before { stub_cloudflare_env(token: nil, account_id: nil, zone_id: nil) }

      it "returns a failure result" do
        result = service.call

        expect(result.success?).to be(false)
        expect(result.error).to eq(:cloudflare_disabled)
      end
    end

    context "when the hostname is active" do
      before do
        stub_cloudflare_env
        allow(HTTParty).to receive(:get).and_return(api_response)
      end

      let(:api_response) do
        instance_double(
          HTTParty::Response,
          success?: true,
          parsed_response: {
            "result" => {
              "id" => "abc123",
              "ssl" => { "status" => "active" },
              "ownership_verification_http" => {
                "http_url" => "https://demo.example.com/.well-known/cf-custom-hostname-challenge/abc123",
                "http_body" => "verification-body"
              }
            }
          },
          code: 200
        )
      end

      it "marks the domain active and stores verification payload" do
        travel_to Time.zone.local(2024, 1, 1, 12, 0, 0)

        result = service.call

        publishing_domain.reload
        expect(publishing_domain.status).to eq("active")
        expect(publishing_domain.cloudflare_ssl_status).to eq("active")
        expect(publishing_domain.verified_at).to eq(Time.zone.local(2024, 1, 1, 12, 0, 0))
        expect(publishing_domain.verification_http_path).to eq("/.well-known/cf-custom-hostname-challenge/abc123")
        expect(publishing_domain.verification_http_body).to eq("verification-body")

        expect(result.success?).to be(true)
        expect(result.data[:ssl_status]).to eq("active")
      end
    end

    context "when the hostname still pending" do
      before do
        stub_cloudflare_env
        allow(HTTParty).to receive(:get).and_return(api_response)
      end

      let(:api_response) do
        instance_double(
          HTTParty::Response,
          success?: true,
          parsed_response: {
            "result" => {
              "id" => "abc123",
              "ssl" => { "status" => "pending_validation" }
            }
          },
          code: 200
        )
      end

      it "keeps the domain provisioning but updates ssl status" do
        result = service.call

        publishing_domain.reload
        expect(publishing_domain.status).to eq("provisioning")
        expect(publishing_domain.cloudflare_ssl_status).to eq("pending_validation")
        expect(publishing_domain.verified_at).to be_nil

        expect(result.success?).to be(true)
        expect(result.data[:ssl_status]).to eq("pending_validation")
      end
    end

    context "when Cloudflare returns an error" do
      before do
        stub_cloudflare_env
        allow(HTTParty).to receive(:get).and_return(api_response)
      end

      let(:api_response) do
        instance_double(
          HTTParty::Response,
          success?: false,
          parsed_response: {
            "errors" => [{ "message" => "Hostname not found" }]
          },
          code: 404
        )
      end

      it "records the error and returns failure" do
        result = service.call

        expect(result.success?).to be(false)
        expect(result.error).to eq(:api_error)
        expect(result.data[:http_status]).to eq(404)
        expect(publishing_domain.reload.last_error).to include("Hostname not found")
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
