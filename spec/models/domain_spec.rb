# == Schema Information
#
# Table name: domains
#
#  id            :bigint           not null, primary key
#  dkim_status   :string           default("pending")
#  dmarc_added   :boolean          default(FALSE)
#  error_message :string
#  name          :string
#  public_key    :string
#  region        :string           default("us-east-1")
#  spf_status    :string           default("pending")
#  status        :string           default("pending")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#  ses_tenant_id :string
#
# Indexes
#
#  index_domains_on_name                                   (name) UNIQUE
#  index_domains_on_newsletter_id                          (newsletter_id)
#  index_domains_on_ses_tenant_id                          (ses_tenant_id)
#  index_domains_on_status_and_dkim_status_and_spf_status  (status,dkim_status,spf_status)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe Domain, type: :model do
  let(:newsletter) { create(:newsletter) }
  let(:domain) { build(:domain, newsletter: newsletter, name: "example.com") }

  describe "#register_or_sync" do
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
      allow(mock_ses_service).to receive(:region).and_return('us-east-1')
    end

    context "when creating a new identity" do
      before do
        domain.public_key = nil  # Ensure it's a new identity
        domain.save!
        allow(mock_ses_service).to receive(:create_identity).and_return('mock-public-key')
        allow(mock_ses_service).to receive(:get_identity).and_return(mock_identity_response)
      end

      it "creates identity without tenant when tenant_name is nil" do
        expect(mock_ses_service).to receive(:create_identity).with(tenant_name: nil)
        expect(mock_tenant_service).not_to receive(:associate_identity)

        domain.register_or_sync(tenant_name: nil)

        expect(domain.reload.public_key).to eq('mock-public-key')
        expect(domain.ses_tenant_id).to be_nil
      end

      it "creates identity and associates with tenant when tenant_name provided" do
        tenant_name = "newsletter-123-abc456"

        expect(mock_ses_service).to receive(:create_identity).with(tenant_name: tenant_name)
        expect(mock_tenant_service).to receive(:associate_identity).with(tenant_name, "example.com")

        domain.register_or_sync(tenant_name: tenant_name)

        expect(domain.reload.public_key).to eq('mock-public-key')
        expect(domain.ses_tenant_id).to eq(tenant_name)
      end
    end

    context "when identity already exists" do
      before do
        domain.public_key = 'existing-public-key'
        domain.save!
        allow(mock_ses_service).to receive(:get_identity).and_return(mock_identity_response)
      end

      it "syncs attributes without associating tenant when tenant_name is nil" do
        expect(mock_ses_service).to receive(:get_identity)
        expect(mock_tenant_service).not_to receive(:associate_identity)
        expect(mock_ses_service).not_to receive(:create_identity)

        domain.register_or_sync(tenant_name: nil)

        expect(domain.ses_tenant_id).to be_nil
      end

      it "associates with tenant when tenant newly added" do
        tenant_name = "newsletter-123-abc456"

        expect(mock_ses_service).to receive(:get_identity)
        expect(mock_tenant_service).to receive(:associate_identity).with(tenant_name, "example.com")

        domain.register_or_sync(tenant_name: tenant_name)

        expect(domain.reload.ses_tenant_id).to eq(tenant_name)
      end

      it "does not re-associate when tenant_id unchanged" do
        tenant_name = "newsletter-123-abc456"
        domain.update!(ses_tenant_id: tenant_name)

        expect(mock_ses_service).to receive(:get_identity)
        expect(mock_tenant_service).not_to receive(:associate_identity)

        domain.register_or_sync(tenant_name: tenant_name)
      end
    end
  end
end
