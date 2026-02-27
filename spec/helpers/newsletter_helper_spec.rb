require "rails_helper"

RSpec.describe NewsletterHelper, type: :helper do
  describe "#newsletter_datetime" do
    it "returns blank values when datetime is nil" do
      expect(helper.newsletter_datetime(nil)).to eq({ date: "", time: "" })
    end

    it "always formats datetime in UTC" do
      non_utc_time = Time.new(2026, 2, 27, 0, 30, 0, "+05:30")

      expect(helper.newsletter_datetime(non_utc_time)).to eq({
        date: "February 26, 2026",
        time: "07:00 PM UTC"
      })
    end
  end
end
