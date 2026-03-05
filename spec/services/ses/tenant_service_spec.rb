require "rails_helper"

RSpec.describe SES::TenantService do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }
  let!(:ses_tenant) { create(:ses_tenant, :pending, newsletter: newsletter, name: "tenant-1") }
  let(:ses_client) do
    Aws::SESV2::Client.new(
      stub_responses: true,
      region: "us-east-1",
      credentials: Aws::Credentials.new("stub-key", "stub-secret")
    )
  end
  let(:service) { described_class.new(newsletter: newsletter) }

  before do
    allow(AppConfig).to receive(:get).and_call_original
    allow(AppConfig).to receive(:get!).and_call_original
    allow(AppConfig).to receive(:get).with("AWS_REGION", BaseAwsService::REGION).and_return("us-east-1")
    allow(AppConfig).to receive(:get).with("PICO_SENDING_DOMAIN", "picoletter.com").and_return("picoletter.com")
    allow(AppConfig).to receive(:get!).with("AWS_ACCESS_KEY_ID").and_return("stub-key")
    allow(AppConfig).to receive(:get!).with("AWS_SECRET_ACCESS_KEY").and_return("stub-secret")
    allow(AppConfig).to receive(:get!).with("AWS_ACCOUNT_ID").and_return("123456789012")
    allow(AppConfig).to receive(:get!).with("AWS_SES_CONFIGURATION_SET").and_return("Picoletter")
    allow(Aws::SESV2::Client).to receive(:new).and_return(ses_client)
  end

  describe "#ensure_tenant!" do
    it "uses existing tenant from SES when available" do
      ses_client.stub_responses(
        :get_tenant,
        {
          tenant: {
            tenant_name: "tenant-1",
            tenant_id: "tenant-id-1",
            tenant_arn: "arn:aws:ses:us-east-1:123456789012:tenant/tenant-1",
            sending_status: "ENABLED"
          }
        }
      )

      result = service.ensure_tenant!

      expect(result).to be_ready
      expect(result.arn).to eq("arn:aws:ses:us-east-1:123456789012:tenant/tenant-1")
      expect(ses_client.api_requests.map { |request| request[:operation_name] }).to eq([ :get_tenant ])
    end

    it "creates tenant in SES when missing" do
      ses_client.stub_responses(:get_tenant, "NotFoundException")
      ses_client.stub_responses(
        :create_tenant,
        {
          tenant_name: "tenant-1",
          tenant_id: "tenant-id-2",
          tenant_arn: "arn:aws:ses:us-east-1:123456789012:tenant/tenant-1",
          sending_status: "ENABLED"
        }
      )

      result = service.ensure_tenant!

      expect(result).to be_ready
      expect(result.arn).to eq("arn:aws:ses:us-east-1:123456789012:tenant/tenant-1")
      expect(ses_client.api_requests.map { |request| request[:operation_name] }).to eq([ :get_tenant, :create_tenant ])
    end

    it "marks tenant failed when ensure operation errors" do
      ses_client.stub_responses(:get_tenant, "BadRequestException")

      expect {
        service.ensure_tenant!
      }.to raise_error(Aws::SESV2::Errors::BadRequestException)

      expect(ses_tenant.reload.status).to eq("failed")
      expect(ses_tenant.last_error).to include("Aws::SESV2::Errors::BadRequestException")
    end
  end

  describe "#sync_resources!" do
    it "associates configuration set and identities using SES tenant APIs" do
      create(:domain, newsletter: newsletter, name: "example.com")
      newsletter.reload
      ses_client.stub_responses(
        :get_tenant,
        {
          tenant: {
            tenant_name: "tenant-1",
            tenant_id: "tenant-id-1",
            tenant_arn: "arn:aws:ses:us-east-1:123456789012:tenant/tenant-1",
            sending_status: "ENABLED"
          }
        }
      )
      ses_client.stub_responses(:list_resource_tenants, { resource_tenants: [], next_token: nil })
      ses_client.stub_responses(:create_tenant_resource_association, {})

      service.sync_resources!

      association_requests = ses_client.api_requests.select do |request|
        request[:operation_name] == :create_tenant_resource_association
      end
      associated_resource_arns = association_requests.map { |request| request[:params][:resource_arn] }

      expect(associated_resource_arns).to contain_exactly(
        "arn:aws:ses:us-east-1:123456789012:configuration-set/Picoletter",
        "arn:aws:ses:us-east-1:123456789012:identity/mail.picoletter.com",
        "arn:aws:ses:us-east-1:123456789012:identity/example.com"
      )
    end
  end
end
