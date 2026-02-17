require 'rails_helper'

RSpec.describe Newsletter, "#setup_sending_domain" do
  describe "registering an invalid domain" do
    let!(:newsletter) { create(:newsletter) }

    it "raises an error" do
      sending_params = { reply_to: "reply_to@invalid", sending_address: "sending_address@invalid" }
      expect { newsletter.setup_sending_domain(sending_params) }.to raise_error(Newsletter::InvalidDomainError, "Domain name invalid")
    end
  end

  describe "registering already registered domain" do
    let!(:user) { create(:user) }
    let!(:newsletter) { create(:newsletter, user_id: user.id) }
    let!(:another_newsletter) { create(:newsletter, user_id: user.id) }
    let!(:domain) { create(:domain, name: 'example.com', newsletter_id: another_newsletter.id, status: "success", dkim_status: "success", spf_status: "success") }
    let(:sending_params) { { reply_to: "test@example.com", sending_address: "test@example.com" } }

    it 'raises an error' do
      expect { newsletter.setup_sending_domain(sending_params) }.to raise_error(Newsletter::DomainClaimedError, "Domain already in use")
    end
  end

  describe "fresh domain setup" do
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
      newsletter.setup_sending_domain(sending_params)

      expect(newsletter.reload.reply_to).to eq('hey@example.com')
      expect(newsletter.sending_address).to eq('hey@example.com')

      domain = Domain.find_by(newsletter: newsletter)
      expect(domain).to be_present
      expect(domain.name).to eq('example.com')
      expect(domain.public_key).to eq('mock-public-key')
      expect(domain.region).to eq('us-east-1')

      expect(domain.status).to eq('success')
      expect(domain.dkim_status).to eq('success')
      expect(domain.spf_status).to eq('success')

      expect(mock_ses_service).to have_received(:create_identity)
      expect(mock_ses_service).to have_received(:get_identity)
    end

    context "when SES service fails" do
      before do
        allow(mock_ses_service).to receive(:create_identity).and_raise(StandardError.new("AWS SES Error"))
      end

      it 'rolls back the transaction' do
        expect {
          newsletter.setup_sending_domain(sending_params)
        }.to raise_error(StandardError, "AWS SES Error")

        expect(Domain.find_by(newsletter: newsletter)).to be_nil
        expect(newsletter.reload.sending_address).not_to eq('hey@example.com')
      end
    end
  end

  describe "has existing domain" do
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
      newsletter.setup_sending_domain(sending_params)

      expect { existing_domain.reload }.to raise_error(ActiveRecord::RecordNotFound)

      expect(newsletter.reload.reply_to).to eq('test@new.com')
      expect(newsletter.sending_address).to eq('test@new.com')

      new_domain = Domain.find_by(name: 'new.com')
      expect(new_domain).to be_present
      expect(new_domain.public_key).to eq('mock-public-key')
      expect(new_domain.status).to eq('success')

      expect(mock_ses_service).to have_received(:delete_identity)
      expect(mock_ses_service).to have_received(:create_identity)
    end
  end

  describe "re-registering same domain" do
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
      newsletter.setup_sending_domain(sending_params)

      expect(newsletter.reload.reply_to).to eq('test@example.com')
      expect(newsletter.sending_address).to eq('test@example.com')

      existing_domain.reload
      expect(existing_domain.status).to eq('success')
      expect(existing_domain.dkim_status).to eq('success')
      expect(existing_domain.spf_status).to eq('success')

      expect(mock_ses_service).to have_received(:get_identity)
      expect(mock_ses_service).not_to have_received(:create_identity)
      expect(mock_ses_service).not_to have_received(:delete_identity)
    end
  end
end
