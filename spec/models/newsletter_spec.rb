# == Schema Information
#
# Table name: newsletters
#
#  id                    :bigint           not null, primary key
#  auto_reminder_enabled :boolean          default(TRUE), not null
#  description           :text
#  dns_records           :json
#  email_css             :text
#  email_footer          :text             default("")
#  enable_archive        :boolean          default(TRUE)
#  font_preference       :string           default("sans-serif")
#  primary_color         :string           default("#09090b")
#  reply_to              :string
#  sending_address       :string
#  sending_name          :string
#  settings              :jsonb            not null
#  slug                  :string           not null
#  status                :string
#  template              :string
#  timezone              :string           default("UTC"), not null
#  title                 :string
#  website               :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  domain_id             :string
#  ses_tenant_id         :string
#  user_id               :integer          not null
#
# Indexes
#
#  index_newsletters_on_ses_tenant_id  (ses_tenant_id)
#  index_newsletters_on_settings       (settings) USING gin
#  index_newsletters_on_slug           (slug)
#  index_newsletters_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Newsletter, type: :model do
  let(:user) { create(:user) }
  subject { build(:newsletter, user: user) }

  before do
    # Stub ses_tenants_enabled? for non-tenant tests
    allow(AppConfig).to receive(:ses_tenants_enabled?).and_return(false)
  end

  describe "validations" do
    it { should belong_to(:user) }
    it { should have_many(:subscribers) }
    it { should have_many(:posts) }
    it { should have_many(:labels) }
    it { should have_many(:memberships) }
    it { should have_many(:members).through(:memberships) }
    it { should have_many(:emails).through(:posts) }

    it { should validate_presence_of(:title) }

    describe "slug validation" do
      it "validates uniqueness of slug" do
        existing = create(:newsletter, user: user, title: "First Newsletter")
        duplicate = build(:newsletter, user: user, title: "Second Newsletter", slug: existing.slug)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:slug]).to include("has already been taken")
      end

      it "auto-generates slug from title" do
        newsletter = create(:newsletter, user: user, title: "My Cool Newsletter")
        expect(newsletter.slug).to eq("my-cool-newsletter")
      end

      it "ensures generated slug is unique" do
        first = create(:newsletter, user: user, title: "Same Title")
        second = create(:newsletter, user: user, title: "Same Title")
        expect(second.slug).to match(/^same-title-\d+$/)
      end
    end
  end

  describe "redirect URL validations" do
    describe "#redirect_after_subscribe" do
      it "allows valid https URLs" do
        subject.redirect_after_subscribe = "https://example.com/thank-you"
        expect(subject).to be_valid
      end

      it "allows valid http URLs" do
        subject.redirect_after_subscribe = "http://example.com/thank-you"
        expect(subject).to be_valid
      end

      it "rejects invalid URLs" do
        subject.redirect_after_subscribe = "not-a-url"
        expect(subject).not_to be_valid
        expect(subject.errors[:redirect_after_subscribe]).to include("must be a valid http or https URL")
      end

      it "allows blank values" do
        subject.redirect_after_subscribe = ""
        expect(subject).to be_valid
      end

      it "rejects URLs with invalid protocols" do
        subject.redirect_after_subscribe = "ftp://example.com"
        expect(subject).not_to be_valid
        expect(subject.errors[:redirect_after_subscribe]).to include("must be a valid http or https URL")
      end
    end

    describe "#redirect_after_confirm" do
      it "allows valid https URLs" do
        subject.redirect_after_confirm = "https://example.com/welcome"
        expect(subject).to be_valid
      end

      it "allows valid http URLs" do
        subject.redirect_after_confirm = "http://example.com/welcome"
        expect(subject).to be_valid
      end

      it "rejects invalid URLs" do
        subject.redirect_after_confirm = "not-a-url"
        expect(subject).not_to be_valid
        expect(subject.errors[:redirect_after_confirm]).to include("must be a valid http or https URL")
      end

      it "allows blank values" do
        subject.redirect_after_confirm = ""
        expect(subject).to be_valid
      end

      it "rejects URLs with invalid protocols" do
        subject.redirect_after_confirm = "ftp://example.com"
        expect(subject).not_to be_valid
        expect(subject.errors[:redirect_after_confirm]).to include("must be a valid http or https URL")
      end
    end
  end

  describe "store accessors" do
    it "provides getter and setter for redirect_after_subscribe" do
      subject.redirect_after_subscribe = "https://example.com/thank-you"
      expect(subject.redirect_after_subscribe).to eq("https://example.com/thank-you")
    end

    it "provides getter and setter for redirect_after_confirm" do
      subject.redirect_after_confirm = "https://example.com/welcome"
      expect(subject.redirect_after_confirm).to eq("https://example.com/welcome")
    end

    it "stores URLs in the settings JSON column" do
      subject.redirect_after_subscribe = "https://example.com/thank-you"
      subject.redirect_after_confirm = "https://example.com/welcome"
      subject.save!

      reloaded = Newsletter.find(subject.id)
      expect(reloaded.settings["redirect_after_subscribe"]).to eq("https://example.com/thank-you")
      expect(reloaded.settings["redirect_after_confirm"]).to eq("https://example.com/welcome")
    end
  end

  describe "membership methods" do
    let(:newsletter) { create(:newsletter, user: user) }
    let(:member_user) { create(:user) }
    let!(:membership) { create(:membership, user: member_user, newsletter: newsletter, role: :editor) }

    describe "#owner?" do
      it "returns true for the newsletter owner" do
        expect(newsletter.owner?(user)).to be true
      end

      it "returns false for members" do
        expect(newsletter.owner?(member_user)).to be false
      end

      it "returns false for non-members" do
        other_user = create(:user)
        expect(newsletter.owner?(other_user)).to be false
      end
    end

    describe "#member?" do
      it "returns true for members" do
        expect(newsletter.member?(member_user)).to be true
      end

      it "returns true for the owner (who has membership)" do
        # Newsletter creation should create owner membership via callback
        expect(newsletter.member?(user)).to be true
      end

      it "returns false for non-members" do
        other_user = create(:user)
        expect(newsletter.member?(other_user)).to be false
      end
    end

    describe "#user_role" do
      it "returns :owner for the newsletter owner" do
        expect(newsletter.user_role(user)).to eq(:owner)
      end

      it "returns the membership role for members" do
        expect(newsletter.user_role(member_user)).to eq(:editor)
      end

      it "returns nil for non-members" do
        other_user = create(:user)
        expect(newsletter.user_role(other_user)).to be_nil
      end
    end
  end

  describe "callbacks" do
    describe "after_create" do
      it "creates an administrator membership for the owner" do
        newsletter = create(:newsletter, user: user)

        owner_membership = newsletter.memberships.find_by(user: user)
        expect(owner_membership).to be_present
        expect(owner_membership.role).to eq('administrator')
      end
    end
  end

  describe "SES tenant management" do
    let(:mock_tenant_service) { double("SES::TenantService") }
    let(:config_set) { "picoletter-config" }

    before do
      allow(SES::TenantService).to receive(:new).and_return(mock_tenant_service)
      allow(AppConfig).to receive(:get).and_call_original
      allow(AppConfig).to receive(:get).with("AWS_SES_CONFIGURATION_SET").and_return(config_set)
    end

    describe "ses_tenant_id validation" do
      it "allows valid tenant IDs" do
        subject.ses_tenant_id = "newsletter-123-abc456"
        expect(subject).to be_valid
      end

      it "allows nil tenant IDs" do
        subject.ses_tenant_id = nil
        expect(subject).to be_valid
      end

      it "rejects invalid tenant IDs with uppercase" do
        subject.ses_tenant_id = "Newsletter-123"
        expect(subject).not_to be_valid
        expect(subject.errors[:ses_tenant_id]).to be_present
      end

      it "rejects invalid tenant IDs with underscores" do
        subject.ses_tenant_id = "newsletter_123"
        expect(subject).not_to be_valid
        expect(subject.errors[:ses_tenant_id]).to be_present
      end

      it "rejects tenant IDs longer than 64 characters" do
        subject.ses_tenant_id = "a" * 65
        expect(subject).not_to be_valid
        expect(subject.errors[:ses_tenant_id]).to be_present
      end
    end

    describe "#generate_tenant_name" do
      it "generates a tenant name with newsletter ID and random suffix" do
        newsletter = create(:newsletter, user: user)
        tenant_name = newsletter.generate_tenant_name

        expect(tenant_name).to match(/^newsletter-#{newsletter.id}-[a-f0-9]{8}$/)
      end
    end

    describe "after_create :create_ses_tenant" do
      context "when SES tenants are enabled" do
        before do
          allow(AppConfig).to receive(:ses_tenants_enabled?).and_return(true)
        end

        it "creates an SES tenant and stores the tenant ID" do
          expect(mock_tenant_service).to receive(:create_tenant).with(
            anything,
            config_set
          )

          newsletter = create(:newsletter, user: user)

          expect(newsletter.ses_tenant_id).to be_present
          expect(newsletter.ses_tenant_id).to match(/^newsletter-#{newsletter.id}-[a-f0-9]{8}$/)
        end

        it "does not create tenant if ses_tenant_id already exists" do
          newsletter = build(:newsletter, user: user, ses_tenant_id: "existing-tenant")

          expect(mock_tenant_service).not_to receive(:create_tenant)

          newsletter.save!
        end

        it "does not raise error if tenant creation fails" do
          allow(mock_tenant_service).to receive(:create_tenant).and_raise(StandardError.new("AWS Error"))

          expect {
            create(:newsletter, user: user)
          }.not_to raise_error
        end

        it "logs error if tenant creation fails" do
          allow(mock_tenant_service).to receive(:create_tenant).and_raise(StandardError.new("AWS Error"))
          allow(Rails.logger).to receive(:error)

          create(:newsletter, user: user)

          expect(Rails.logger).to have_received(:error).with(/Failed to create tenant/)
        end
      end

      context "when SES tenants are disabled" do
        before do
          allow(AppConfig).to receive(:ses_tenants_enabled?).and_return(false)
        end

        it "does not create an SES tenant" do
          expect(mock_tenant_service).not_to receive(:create_tenant)

          newsletter = create(:newsletter, user: user)
          expect(newsletter.ses_tenant_id).to be_nil
        end
      end
    end

    describe "before_destroy :cleanup_ses_tenant" do
      let(:newsletter) { create(:newsletter, user: user, ses_tenant_id: "newsletter-123-abc456") }
      let(:domain) { create(:domain, newsletter: newsletter, name: "example.com", ses_tenant_id: "newsletter-123-abc456") }

      before do
        domain # Create domain
      end

      it "disassociates domain, config set, and deletes tenant" do
        expect(mock_tenant_service).to receive(:disassociate_identity).with(
          "newsletter-123-abc456",
          "example.com"
        )
        expect(mock_tenant_service).to receive(:disassociate_configuration_set).with(
          "newsletter-123-abc456",
          config_set
        )
        expect(mock_tenant_service).to receive(:delete_tenant).with("newsletter-123-abc456")

        newsletter.destroy
      end

      it "handles missing domain gracefully" do
        newsletter_without_domain = create(:newsletter, user: user, ses_tenant_id: "newsletter-456-def789")

        expect(mock_tenant_service).to receive(:disassociate_configuration_set)
        expect(mock_tenant_service).to receive(:delete_tenant)
        expect(mock_tenant_service).not_to receive(:disassociate_identity)

        newsletter_without_domain.destroy
      end

      it "does not raise error if cleanup fails" do
        allow(mock_tenant_service).to receive(:disassociate_identity).and_raise(StandardError.new("AWS Error"))
        allow(mock_tenant_service).to receive(:disassociate_configuration_set)
        allow(mock_tenant_service).to receive(:delete_tenant)
        allow(Rails.logger).to receive(:error)

        expect {
          newsletter.destroy
        }.not_to raise_error
      end

      it "logs error if cleanup fails" do
        allow(mock_tenant_service).to receive(:disassociate_identity).and_raise(StandardError.new("AWS Error"))
        allow(mock_tenant_service).to receive(:disassociate_configuration_set)
        allow(mock_tenant_service).to receive(:delete_tenant)
        allow(Rails.logger).to receive(:error)

        newsletter.destroy

        expect(Rails.logger).to have_received(:error).with(/Failed to cleanup tenant/)
      end

      it "skips cleanup if ses_tenant_id is not present" do
        newsletter_without_tenant = create(:newsletter, user: user, ses_tenant_id: nil)

        expect(mock_tenant_service).not_to receive(:delete_tenant)

        newsletter_without_tenant.destroy
      end
    end
  end
end
