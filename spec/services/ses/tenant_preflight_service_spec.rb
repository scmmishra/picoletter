require "rails_helper"

RSpec.describe SES::TenantPreflightService do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }

  describe "#ensure_ready!" do
    it "returns tenant name when tenant is ready" do
      tenant = create(:ses_tenant, newsletter: newsletter, status: :ready, name: "tenant-123")

      result = described_class.new(newsletter).ensure_ready!

      expect(result).to eq("tenant-123")
      expect(tenant.reload.last_checked_at).to be_present
    end

    it "marks tenant as failed and raises when tenant is not ready" do
      tenant = create(:ses_tenant, :pending, newsletter: newsletter, name: "tenant-123")

      expect(Rails.error).to receive(:report).with(
        an_instance_of(SES::TenantPreflightFailed),
        hash_including(context: hash_including(newsletter_id: newsletter.id, ses_tenant_id: tenant.id))
      )

      expect {
        described_class.new(newsletter).ensure_ready!
      }.to raise_error(SES::TenantPreflightFailed, /not ready/)

      expect(tenant.reload.status).to eq("failed")
      expect(tenant.last_error).to include("not ready")
      expect(tenant.last_checked_at).to be_present
    end

    it "creates a failed tenant record when missing" do
      expect(Rails.error).to receive(:report).with(
        an_instance_of(SES::TenantPreflightFailed),
        hash_including(context: hash_including(newsletter_id: newsletter.id))
      )

      expect {
        described_class.new(newsletter).ensure_ready!
      }.to raise_error(SES::TenantPreflightFailed)

      tenant = newsletter.reload.ses_tenant
      expect(tenant).to be_present
      expect(tenant.status).to eq("failed")
    end
  end
end
