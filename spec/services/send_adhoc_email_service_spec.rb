require "rails_helper"
require "tempfile"

RSpec.describe SendAdhocEmailService do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, :with_ready_ses_tenant, user: user) }
  let(:csv_file) { Tempfile.new([ "adhoc", ".csv" ]) }
  let(:template_file) { Tempfile.new([ "adhoc_template", ".liquid" ]) }
  let(:template_name) { template_file.path.delete_suffix(".liquid") }
  let(:service) { described_class.new(newsletter.id, template_name, "Subject", csv_file.path) }

  before do
    csv_file.write("email,name\nreader@example.com,Reader\n")
    csv_file.rewind
    template_file.write("<p>Hello {{ data.name }}</p>")
    template_file.rewind
  end

  after do
    csv_file.close!
    template_file.close!
  end

  describe "#send_emails" do
    it "passes tenant_name to SES when preflight succeeds" do
      preflight_service = instance_double(SES::TenantPreflightService, ensure_ready!: "tenant-1")
      email_service = instance_double(SES::EmailService)
      allow(SES::TenantPreflightService).to receive(:new).with(newsletter).and_return(preflight_service)
      allow(SES::EmailService).to receive(:new).and_return(email_service)
      allow(email_service).to receive(:send)

      service.send_emails

      expect(email_service).to have_received(:send).with(hash_including(tenant_name: "tenant-1"))
    end

    it "fails the operation when preflight fails" do
      preflight_service = instance_double(SES::TenantPreflightService)
      allow(SES::TenantPreflightService).to receive(:new).with(newsletter).and_return(preflight_service)
      allow(preflight_service).to receive(:ensure_ready!).and_raise(SES::TenantPreflightFailed, "tenant not ready")
      allow(SES::EmailService).to receive(:new)

      expect {
        service.send_emails
      }.to raise_error(SES::TenantPreflightFailed, "tenant not ready")
      expect(SES::EmailService).not_to have_received(:new)
    end
  end
end
