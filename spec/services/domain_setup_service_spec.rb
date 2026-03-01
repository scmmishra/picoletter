require 'rails_helper'

RSpec.describe Newsletter, "#connect_sending_domain" do
  describe "registering an invalid domain" do
    let!(:newsletter) { create(:newsletter) }

    it "raises an error" do
      expect { newsletter.connect_sending_domain("invalid") }.to raise_error(Newsletter::InvalidDomainError, "Domain name invalid")
    end
  end

  describe "registering already registered domain" do
    let!(:user) { create(:user) }
    let!(:newsletter) { create(:newsletter, user_id: user.id) }
    let!(:another_newsletter) { create(:newsletter, user_id: user.id) }
    let!(:domain) { create(:domain, name: 'example.com', newsletter_id: another_newsletter.id, status: "success", dkim_status: "success", spf_status: "success") }

    it 'raises an error' do
      expect { newsletter.connect_sending_domain("example.com") }.to raise_error(Newsletter::DomainClaimedError, "Domain already in use")
    end
  end

  describe "fresh domain setup" do
    let!(:user) { create(:user, name: "Fresh Service", email: 'fresh-service@example.com') }
    let!(:newsletter) { create(:newsletter, slug: 'fresh-newsletter', sending_address: "fresh-newsletter@mail.picoletter.com", user_id: user.id) }

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
      allow(mock_ses_service).to receive(:delete_identity)
    end

    it 'creates a new identity and syncs the status' do
      newsletter.connect_sending_domain("Example.com")

      domain = Domain.find_by(newsletter: newsletter)
      expect(domain).to be_present
      expect(domain.name).to eq('example.com')
      expect(domain.public_key).to eq('mock-public-key')
      expect(domain.region).to eq('us-east-1')

      expect(domain.status).to eq('success')
      expect(domain.dkim_status).to eq('success')
      expect(domain.spf_status).to eq('success')
      expect(newsletter.reload.sending_address).to eq("fresh-newsletter@example.com")

      expect(mock_ses_service).to have_received(:create_identity)
      expect(mock_ses_service).to have_received(:get_identity)
    end

    context "when existing sending address is blank" do
      let!(:newsletter) { create(:newsletter, slug: "fresh-newsletter", sending_address: nil, user_id: user.id) }

      it "uses the user's first name for sending address local-part" do
        newsletter.connect_sending_domain("example.com")

        expect(newsletter.reload.sending_address).to eq("fresh@example.com")
      end

      it "does not leave sending_address blank when updated later" do
        newsletter.connect_sending_domain("example.com")

        newsletter.update!(sending_address: nil)
        expect(newsletter.reload.sending_address).to eq("fresh@example.com")
      end
    end

    context "when existing sending address already uses the connected domain" do
      let!(:newsletter) { create(:newsletter, slug: "fresh-newsletter", sending_address: "Fresh+tag@Example.com", user_id: user.id) }

      it "keeps the sending address unchanged" do
        newsletter.connect_sending_domain("example.com")

        expect(newsletter.reload.sending_address).to eq("Fresh+tag@Example.com")
      end
    end

    context "when user first name cannot be normalized" do
      let!(:user) { create(:user, name: "!!!", email: "symbols-only@example.com") }
      let!(:newsletter) { create(:newsletter, slug: "fresh-newsletter", sending_address: nil, user_id: user.id) }

      it "falls back to newsletter slug" do
        newsletter.connect_sending_domain("example.com")

        expect(newsletter.reload.sending_address).to eq("fresh-newsletter@example.com")
      end
    end

    context "when SES service fails" do
      before do
        allow(mock_ses_service).to receive(:create_identity).and_raise(StandardError.new("AWS SES Error"))
      end

      it 'rolls back the transaction' do
        expect {
          newsletter.connect_sending_domain("example.com")
        }.to raise_error(StandardError, "AWS SES Error")

        expect(Domain.find_by(newsletter: newsletter)).to be_nil
      end
    end

    context "when local updates fail after SES identity registration" do
      before do
        allow(newsletter).to receive(:update!).and_raise(StandardError.new("DB write failed"))
      end

      it "cleans up SES identity and rolls back domain setup" do
        expect {
          newsletter.connect_sending_domain("example.com")
        }.to raise_error(StandardError, "DB write failed")

        expect(mock_ses_service).to have_received(:create_identity)
        expect(mock_ses_service).to have_received(:delete_identity)
        expect(Domain.find_by(newsletter: newsletter)).to be_nil
      end
    end
  end

  describe "domain already connected" do
    let!(:user) { create(:user) }
    let!(:newsletter) { create(:newsletter, user_id: user.id) }
    let!(:existing_domain) { create(:domain, name: 'existing.com', newsletter_id: newsletter.id, status: "success", dkim_status: "success", spf_status: "success") }

    it 'raises an error when trying to connect another domain' do
      expect {
        newsletter.connect_sending_domain("new.com")
      }.to raise_error(Newsletter::InvalidDomainError, "A domain is already connected. Disconnect it first.")
    end

    it 'does not create a new domain record' do
      expect {
        newsletter.connect_sending_domain("new.com") rescue nil
      }.not_to change(Domain, :count)
    end
  end
end
