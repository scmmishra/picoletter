require "rails_helper"

RSpec.describe SyncSESTenantJob, type: :job do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }

  it "syncs tenant resources for the newsletter" do
    tenant_service = instance_double(SES::TenantService)
    allow(SES::TenantService).to receive(:new).with(newsletter: newsletter).and_return(tenant_service)
    allow(tenant_service).to receive(:sync_resources!)

    described_class.perform_now(newsletter.id)

    expect(tenant_service).to have_received(:sync_resources!)
  end

  it "ignores missing newsletters" do
    expect {
      described_class.perform_now(-1)
    }.not_to raise_error
  end
end
