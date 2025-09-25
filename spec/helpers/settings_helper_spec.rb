require "rails_helper"

RSpec.describe SettingsHelper, type: :helper do
  let(:newsletter) { instance_double(Newsletter) }

  before do
    allow(helper).to receive(:current_page?).and_return(false)
  end

  describe "#settings_nav_link" do
    it "returns a link when newsletter is absent" do
      html = helper.settings_nav_link("Team", "/team")
      expect(html).to include("Team")
      expect(html).to include("href=\"/team\"")
    end

    it "returns a link when newsletter allows access" do
      allow(newsletter).to receive(:can_read?).with(:team).and_return(true)

      html = helper.settings_nav_link("Team", "/team", newsletter)

      expect(html).to include("Team")
      expect(html).to include("href=\"/team\"")
      expect(html).to include("hover:text-stone-500")
    end

    it "returns empty string when newsletter denies access" do
      allow(newsletter).to receive(:can_read?).with(:team).and_return(false)

      html = helper.settings_nav_link("Team", "/team", newsletter)

      expect(html).to eq("")
    end

    it "marks the current page with active class" do
      allow(newsletter).to receive(:can_read?).with(:team).and_return(true)
      allow(helper).to receive(:current_page?).with("/team").and_return(true)

      html = helper.settings_nav_link("Team", "/team", newsletter)

      expect(html).to include("text-stone-800")
    end
  end

  describe "#should_show_settings_link?" do
    it "permits team link when newsletter can read" do
      allow(newsletter).to receive(:can_read?).with(:team).and_return(true)

      expect(helper.send(:should_show_settings_link?, "team", newsletter)).to be(true)
    end

    it "denies team link when newsletter cannot read" do
      allow(newsletter).to receive(:can_read?).with(:team).and_return(false)

      expect(helper.send(:should_show_settings_link?, "team", newsletter)).to be(false)
    end
  end
end
