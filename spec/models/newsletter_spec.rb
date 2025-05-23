# == Schema Information
#
# Table name: newsletters
#
#  id              :bigint           not null, primary key
#  description     :text
#  dns_records     :json
#  domain          :string
#  domain_verified :boolean          default(FALSE)
#  email_css       :text
#  email_footer    :text             default("")
#  enable_archive  :boolean          default(TRUE)
#  font_preference :string           default("sans-serif")
#  primary_color   :string           default("#09090b")
#  reply_to        :string
#  sending_address :string
#  sending_name    :string
#  settings        :jsonb            not null
#  slug            :string           not null
#  status          :string
#  template        :string
#  timezone        :string           default("UTC"), not null
#  title           :string
#  website         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  domain_id       :string
#  user_id         :integer          not null
#
# Indexes
#
#  index_newsletters_on_settings  (settings) USING gin
#  index_newsletters_on_slug      (slug)
#  index_newsletters_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Newsletter, type: :model do
  let(:user) { create(:user) }
  subject { build(:newsletter, user: user) }

  describe "validations" do
    it { should belong_to(:user) }
    it { should have_many(:subscribers) }
    it { should have_many(:posts) }
    it { should have_many(:labels) }
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
end
