require 'rails_helper'

RSpec.describe DomainSetupService do
  describe "Registring an invalid domain" do
    let!(:newsletter) { create(:newsletter) }

    it "throws an error" do
      sending_params = { reply_to: "reply_to@invalid", sending_address: "sending_address@invalid" }
      domain_setup = DomainSetupService.new(newsletter, sending_params)
      expect { domain_setup.perform }.to raise_error("Domain name invalid")
    end
  end

  describe "Registring already registered domain" do
    let!(:user) { create(:user) }
    let!(:newsletter) { create(:newsletter, user_id: user.id) }
    let!(:another_newsletter) { create(:newsletter, user_id: user.id) }
    let!(:domain) { create(:domain, name: 'example.com',  newsletter_id: another_newsletter.id, status: "success", dkim_status: "success", spf_status: "success") }
    let(:sending_params) { { reply_to: "test@example.com", sending_address: "test@example.com" } }

    it 'throws an error' do
      domain_setup = DomainSetupService.new(newsletter, sending_params)
      expect { domain_setup.perform }.to raise_error("Domain already in use")
    end
  end

  describe "Fresh domain setup" do
    let!(:user) { create(:user, email: 'fresh-service@example.com') }
    let!(:newsletter) { create(:newsletter, slug: 'fresh-newsletter', user_id: user.id) }
    let(:sending_params) { { reply_to: "hey@example.com", sending_address: "hey@example.com" } }

    let(:mock_ses_service) { double("SES::DomainService") }
    let(:mock_identity_response) do
      double(
        dkim_attributes: double(status: 'SUCCESS'),
        mail_from_attributes: double(mail_from_domain_status: 'SUCCESS'),
        verification_status: 'SUCCESS'
      )
    end

    before do
      allow(SES::DomainService).to receive(:new).and_return(mock_ses_service)
      allow(mock_ses_service).to receive(:create_identity).and_return('mock-public-key')
      allow(mock_ses_service).to receive(:get_identity).and_return(mock_identity_response)
      allow(mock_ses_service).to receive(:region).and_return('us-east-1')
    end

    it 'creates a new identity and syncs the status' do
      domain_setup = DomainSetupService.new(newsletter, sending_params)
      domain_setup.perform

      # Check that the newsletter was updated
      expect(newsletter.reload.reply_to).to eq('hey@example.com')
      expect(newsletter.sending_address).to eq('hey@example.com')

      # Check that the domain was created
      domain = Domain.find_by(newsletter: newsletter)
      expect(domain).to be_present
      expect(domain.name).to eq('example.com')
      expect(domain.public_key).to eq('mock-public-key')
      expect(domain.region).to eq('us-east-1')

      # Check domain status
      expect(domain.status).to eq('success')
      expect(domain.dkim_status).to eq('success')
      expect(domain.spf_status).to eq('success')

      # Verify SES service calls
      expect(mock_ses_service).to have_received(:create_identity)
      expect(mock_ses_service).to have_received(:get_identity)
    end

    context "when SES service fails" do
      before do
        allow(mock_ses_service).to receive(:create_identity).and_raise(StandardError.new("AWS SES Error"))
      end

      it 'rolls back the transaction' do
        domain_setup = DomainSetupService.new(newsletter, sending_params)

        expect {
          domain_setup.perform
        }.to raise_error(StandardError, "AWS SES Error")

        expect(Domain.find_by(newsletter: newsletter)).to be_nil
        expect(newsletter.reload.sending_address).not_to eq('hey@example.com')
      end
    end
  end

  describe "Has existing domain" do
    let!(:user) { create(:user) }
    let!(:newsletter) { create(:newsletter, user_id: user.id) }
    let!(:existing_domain) { create(:domain, name: 'existing.com', newsletter_id: newsletter.id, status: "success", dkim_status: "success", spf_status: "success") }
    let(:sending_params) { { reply_to: "test@new.com", sending_address: "test@new.com" } }

    let(:mock_ses_service) { double("SES::DomainService") }
    let(:mock_identity_response) do
      double(
        dkim_attributes: double(status: 'SUCCESS'),
        mail_from_attributes: double(mail_from_domain_status: 'SUCCESS'),
        verification_status: 'SUCCESS'
      )
    end

    before do
      allow(SES::DomainService).to receive(:new).and_return(mock_ses_service)
      allow(mock_ses_service).to receive(:delete_identity)
      allow(mock_ses_service).to receive(:create_identity).and_return('mock-public-key')
      allow(mock_ses_service).to receive(:get_identity).and_return(mock_identity_response)
      allow(mock_ses_service).to receive(:region).and_return('us-east-1')
    end

    it 'removes the existing domain and sets up the new one' do
      domain_setup = DomainSetupService.new(newsletter, sending_params)
      domain_setup.perform

      # Verify old domain was removed
      expect { existing_domain.reload }.to raise_error(ActiveRecord::RecordNotFound)

      # Check that the newsletter was updated
      expect(newsletter.reload.reply_to).to eq('test@new.com')
      expect(newsletter.sending_address).to eq('test@new.com')

      # Check that the new domain was created
      new_domain = Domain.find_by(name: 'new.com')
      expect(new_domain).to be_present
      expect(new_domain.public_key).to eq('mock-public-key')
      expect(new_domain.status).to eq('success')

      # Verify SES service calls
      expect(mock_ses_service).to have_received(:delete_identity)
      expect(mock_ses_service).to have_received(:create_identity)
    end
  end

  describe "Re-registring same domain" do
    let!(:user) { create(:user) }
    let!(:newsletter) { create(:newsletter, user_id: user.id) }
    let!(:existing_domain) { create(:domain, name: 'example.com', public_key: 'mock-key', newsletter_id: newsletter.id, status: "success", dkim_status: "success", spf_status: "success") }
    let(:sending_params) { { reply_to: "test@example.com", sending_address: "test@example.com" } }

    let(:mock_ses_service) { double("SES::DomainService") }
    let(:mock_identity_response) do
      double(
        dkim_attributes: double(status: 'SUCCESS'),
        mail_from_attributes: double(mail_from_domain_status: 'SUCCESS'),
        verification_status: 'SUCCESS'
      )
    end

    before do
      allow(SES::DomainService).to receive(:new).and_return(mock_ses_service)
      allow(mock_ses_service).to receive(:get_identity).and_return(mock_identity_response)
      allow(mock_ses_service).to receive(:create_identity).and_return('mock-public-key')
      allow(mock_ses_service).to receive(:delete_identity).and_return(true)
    end

    it 'only updates newsletter details without changing domain' do
      domain_setup = DomainSetupService.new(newsletter, sending_params)
      domain_setup.perform

      # Check that the newsletter was updated
      expect(newsletter.reload.reply_to).to eq('test@example.com')
      expect(newsletter.sending_address).to eq('test@example.com')

      # Verify domain remains unchanged
      existing_domain.reload
      expect(existing_domain.status).to eq('success')
      expect(existing_domain.dkim_status).to eq('success')
      expect(existing_domain.spf_status).to eq('success')

      # Verify SES service calls
      expect(mock_ses_service).to have_received(:get_identity)
      expect(mock_ses_service).not_to have_received(:create_identity)
      expect(mock_ses_service).not_to have_received(:delete_identity)
    end
  end

  describe "Tenant integration" do
    let!(:user) { create(:user) }
    let!(:newsletter) { create(:newsletter, user_id: user.id, ses_tenant_id: nil) }
    let(:sending_params) { { reply_to: "hey@example.com", sending_address: "hey@example.com" } }

    let(:mock_ses_service) { double("SES::DomainService") }
    let(:mock_tenant_service) { double("SES::TenantService") }
    let(:mock_identity_response) do
      double(
        dkim_attributes: double(status: 'SUCCESS'),
        mail_from_attributes: double(mail_from_domain_status: 'SUCCESS'),
        verification_status: 'SUCCESS'
      )
    end

    before do
      allow(SES::DomainService).to receive(:new).and_return(mock_ses_service)
      allow(SES::TenantService).to receive(:new).and_return(mock_tenant_service)
      allow(mock_ses_service).to receive(:create_identity).and_return('mock-public-key')
      allow(mock_ses_service).to receive(:get_identity).and_return(mock_identity_response)
      allow(mock_ses_service).to receive(:region).and_return('us-east-1')
      allow(AppConfig).to receive(:get).with("AWS_SES_CONFIGURATION_SET").and_return("picoletter-config")
    end

    context "when tenants are enabled and newsletter has no tenant" do
      before do
        allow(AppConfig).to receive(:ses_tenants_enabled?).and_return(true)
      end

      it "creates tenant and associates domain" do
        expect(mock_tenant_service).to receive(:create_tenant).with(
          anything,
          "picoletter-config"
        )
        expect(mock_tenant_service).to receive(:associate_identity).with(
          anything,
          "example.com"
        )
        expect(mock_ses_service).to receive(:create_identity).with(tenant_name: anything)

        domain_setup = DomainSetupService.new(newsletter, sending_params)
        domain_setup.perform

        expect(newsletter.reload.ses_tenant_id).to be_present
        expect(Domain.find_by(newsletter: newsletter).ses_tenant_id).to eq(newsletter.ses_tenant_id)
      end
    end

    context "when tenants are enabled and newsletter has tenant" do
      before do
        newsletter.update!(ses_tenant_id: "newsletter-1-abc123")
        allow(AppConfig).to receive(:ses_tenants_enabled?).and_return(true)
      end

      it "uses existing tenant and associates domain" do
        expect(mock_tenant_service).not_to receive(:create_tenant)
        expect(mock_tenant_service).to receive(:associate_identity).with(
          "newsletter-1-abc123",
          "example.com"
        )
        expect(mock_ses_service).to receive(:create_identity).with(tenant_name: "newsletter-1-abc123")

        domain_setup = DomainSetupService.new(newsletter, sending_params)
        domain_setup.perform

        expect(Domain.find_by(newsletter: newsletter).ses_tenant_id).to eq("newsletter-1-abc123")
      end
    end

    context "when tenants are disabled" do
      before do
        allow(AppConfig).to receive(:ses_tenants_enabled?).and_return(false)
      end

      it "creates domain without tenant" do
        expect(mock_tenant_service).not_to receive(:create_tenant)
        expect(mock_tenant_service).not_to receive(:associate_identity)
        expect(mock_ses_service).to receive(:create_identity).with(tenant_name: nil)

        domain_setup = DomainSetupService.new(newsletter, sending_params)
        domain_setup.perform

        expect(newsletter.reload.ses_tenant_id).to be_nil
        expect(Domain.find_by(newsletter: newsletter).ses_tenant_id).to be_nil
      end
    end
  end
end
