# == Schema Information
#
# Table name: publishing_domains
#
#  id                     :bigint           not null, primary key
#  cloudflare_ssl_status  :string
#  domain_type            :string           default("custom_cname"), not null
#  hostname               :string           not null
#  last_error             :text
#  status                 :string           default("pending"), not null
#  verification_http_body :text
#  verification_http_path :string
#  verification_method    :string
#  verified_at            :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  cloudflare_id          :string
#  newsletter_id          :bigint           not null
#
# Indexes
#
#  index_publishing_domains_on_hostname       (hostname) UNIQUE
#  index_publishing_domains_on_newsletter_id  (newsletter_id) UNIQUE
#
require "rails_helper"

RSpec.describe PublishingDomain, type: :model do
  subject(:publishing_domain) { build(:publishing_domain) }

  let(:newsletter) { build(:newsletter, slug: "my-letter") }

  it { is_expected.to belong_to(:newsletter) }

  it { is_expected.to define_enum_for(:domain_type).with_values(custom_cname: "custom_cname").backed_by_column_of_type(:string) }

  it do
    expect(publishing_domain).to define_enum_for(:status)
      .with_values(pending: "pending", provisioning: "provisioning", active: "active", failed: "failed")
      .backed_by_column_of_type(:string)
  end

  it { is_expected.to validate_presence_of(:hostname) }
  it { is_expected.to validate_uniqueness_of(:hostname).case_insensitive }
  it { is_expected.to validate_uniqueness_of(:newsletter_id) }

  describe ".platform_hostname_for" do
    before do
      allow(AppConfig).to receive(:platform_publishing_domain).and_return("picoletter.page")
    end

    it "returns the platform host derived from the newsletter slug" do
      expect(described_class.platform_hostname_for(newsletter)).to eq("my-letter.picoletter.page")
    end
  end

  describe "#apply_http_verification" do
    let(:publishing_domain) { build(:publishing_domain) }
    let(:payload) do
      {
        "ownership_verification_http" => {
          "http_url" => "https://example.com/.well-known/cf-custom-hostname-challenge/token",
          "http_body" => "challenge-body"
        }
      }
    end

    it "stores the verification path and body extracted from the payload" do
      publishing_domain.apply_http_verification(payload)

      expect(publishing_domain.verification_http_path).to eq("/.well-known/cf-custom-hostname-challenge/token")
      expect(publishing_domain.verification_http_body).to eq("challenge-body")
      expect(publishing_domain.verification_method).to eq("http")
    end

    it "clears the verification attributes when payload is blank" do
      publishing_domain.apply_http_verification(nil)

      expect(publishing_domain.verification_http_path).to be_nil
      expect(publishing_domain.verification_http_body).to be_nil
      expect(publishing_domain.verification_method).to be_nil
    end
  end
end
