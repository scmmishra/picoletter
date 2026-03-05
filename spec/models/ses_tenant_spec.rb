# == Schema Information
#
# Table name: ses_tenants
# Database name: primary
#
#  id              :bigint           not null, primary key
#  arn             :string
#  last_checked_at :datetime
#  last_error      :text
#  last_synced_at  :datetime
#  name            :string           not null
#  ready_at        :datetime
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  newsletter_id   :bigint           not null
#
# Indexes
#
#  index_ses_tenants_on_name           (name) UNIQUE
#  index_ses_tenants_on_newsletter_id  (newsletter_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
require 'rails_helper'

RSpec.describe SESTenant, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:newsletter) }
  end

  describe "validations" do
    subject(:ses_tenant) { create(:ses_tenant) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "#usable_for_send?" do
    it "returns true when tenant is ready and has a name" do
      tenant = build(:ses_tenant, status: :ready, name: "tenant-1")

      expect(tenant.usable_for_send?).to be(true)
    end

    it "returns false when tenant is not ready" do
      tenant = build(:ses_tenant, :pending)

      expect(tenant.usable_for_send?).to be(false)
    end
  end

  describe ".generate_name" do
    it "builds a deterministic tenant name from newsletter id" do
      expect(described_class.generate_name(42)).to eq("picoletter-newsletter-42")
    end
  end
end
