require "rails_helper"

RSpec.describe PublishingDomains::LifecycleService, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:newsletter) { create(:newsletter, title: "My Letter") }
  let(:publishing_domain) { create(:publishing_domain, newsletter: newsletter, hostname: "custom.example.com") }

  subject(:service) { described_class.new(publishing_domain) }

  before do
    allow(AppConfig).to receive(:get).and_call_original
    allow(AppConfig).to receive(:platform_publishing_domain).and_return("picoletter.page")
  end

  after { travel_back }

  describe "#register" do
    context "when Cloudflare integration is disabled" do
      before { disable_cloudflare_env }

      it "returns a manual registration result and keeps the domain pending" do
        result = service.register

        expect(result.success?).to be(true)
        expect(result.error).to be_nil
        expect(result.data[:mode]).to eq(:manual)
        expect(result.data[:expected_cname]).to eq("my-letter.picoletter.page")
        expect(result.data[:instructions]).to match(/CNAME/i)

        publishing_domain.reload
        expect(publishing_domain.status).to eq("pending")
        expect(publishing_domain.last_error).to be_nil
        expect(publishing_domain.cloudflare_id).to be_nil
      end
    end

    context "when Cloudflare integration is enabled" do
      let(:cloudflare_result) do
        Cloudflare::BaseService::Result.new(success?: true, data: { foo: "bar" }, error: nil)
      end

      before { enable_cloudflare_env }

      it "delegates registration to the Cloudflare create service" do
        cf_service = instance_double(Cloudflare::CreateCustomHostnameService, call: cloudflare_result)
        expect(Cloudflare::CreateCustomHostnameService).to receive(:new).with(publishing_domain).and_return(cf_service)

        result = service.register

        expect(result).to eq(cloudflare_result)
      end
    end
  end

  describe "#verify" do
    context "when Cloudflare integration is disabled" do
      before { disable_cloudflare_env }

      it "activates the domain when DNS points to the platform hostname" do
        travel_to Time.zone.local(2024, 1, 1, 12, 0, 0)

        dns_double = instance_double(Resolv::DNS)
        cname_name = instance_double(Resolv::DNS::Name, to_s: "my-letter.picoletter.page.")
        cname_resource = instance_double(Resolv::DNS::Resource::IN::CNAME, name: cname_name)

        expect(Resolv::DNS).to receive(:open).and_yield(dns_double)
        expect(dns_double).to receive(:getresources)
          .with("custom.example.com", Resolv::DNS::Resource::IN::CNAME)
          .and_return([cname_resource])

        result = service.verify

        expect(result.success?).to be(true)
        expect(result.data[:mode]).to eq(:manual)
        expect(result.data[:verified]).to be(true)

        publishing_domain.reload
        expect(publishing_domain.status).to eq("active")
        expect(publishing_domain.verified_at).to eq(Time.zone.local(2024, 1, 1, 12, 0, 0))
        expect(publishing_domain.last_error).to be_nil
      end

      it "returns a failure result when DNS does not match" do
        dns_double = instance_double(Resolv::DNS)

        expect(Resolv::DNS).to receive(:open).and_yield(dns_double)
        expect(dns_double).to receive(:getresources)
          .with("custom.example.com", Resolv::DNS::Resource::IN::CNAME)
          .and_return([])

        result = service.verify

        expect(result.success?).to be(false)
        expect(result.error).to eq(:dns_unverified)
        expect(result.data[:expected_cname]).to eq("my-letter.picoletter.page")
        expect(result.data[:resolved_cnames]).to eq([])

        publishing_domain.reload
        expect(publishing_domain.status).to eq("pending")
        expect(publishing_domain.last_error).to match(/CNAME/i)
        expect(publishing_domain.verified_at).to be_nil
      end
    end

    context "when Cloudflare integration is enabled" do
      let(:cloudflare_result) { Cloudflare::BaseService::Result.new(success?: true, data: {}, error: nil) }

      before { enable_cloudflare_env }

      it "delegates verification to the Cloudflare check service" do
        cf_service = instance_double(Cloudflare::CheckCustomHostnameService, call: cloudflare_result)
        expect(Cloudflare::CheckCustomHostnameService).to receive(:new).with(publishing_domain).and_return(cf_service)

        result = service.verify

        expect(result).to eq(cloudflare_result)
      end
    end
  end

  def disable_cloudflare_env
    allow(AppConfig).to receive(:get).with("CLOUDFLARE_API_TOKEN", nil).and_return(nil)
    allow(AppConfig).to receive(:get).with("CLOUDFLARE_ACCOUNT_ID", nil).and_return(nil)
    allow(AppConfig).to receive(:get).with("CLOUDFLARE_ZONE_ID", nil).and_return(nil)
  end

  def enable_cloudflare_env
    allow(AppConfig).to receive(:get).with("CLOUDFLARE_API_TOKEN", nil).and_return("token")
    allow(AppConfig).to receive(:get).with("CLOUDFLARE_ACCOUNT_ID", nil).and_return("acct")
    allow(AppConfig).to receive(:get).with("CLOUDFLARE_ZONE_ID", nil).and_return("zone")
  end
end
