require "rails_helper"

RSpec.describe "Newsletter Redirect Settings", type: :system do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }

  before do
    sign_in(user)
  end

  describe "configuring redirect URLs" do
    it "allows setting redirect URLs" do
      visit embedding_settings_path(slug: newsletter.slug)

      fill_in "After Subscribe URL", with: "https://example.com/thank-you"
      fill_in "After Confirm URL", with: "https://example.com/welcome"
      click_button "Save Changes"

      expect(page).to have_text("Redirect settings updated successfully")
      
      newsletter.reload
      expect(newsletter.redirect_after_subscribe).to eq("https://example.com/thank-you")
      expect(newsletter.redirect_after_confirm).to eq("https://example.com/welcome")
    end

    it "shows error for invalid URLs" do
      visit embedding_settings_path(slug: newsletter.slug)

      fill_in "After Subscribe URL", with: "not-a-url"
      fill_in "After Confirm URL", with: "also-not-a-url"
      click_button "Save Changes"

      expect(page).to have_text("Failed to update redirect settings")
    end

    it "allows clearing redirect URLs" do
      newsletter.update!(
        redirect_after_subscribe: "https://example.com/thank-you",
        redirect_after_confirm: "https://example.com/welcome"
      )

      visit embedding_settings_path(slug: newsletter.slug)

      fill_in "After Subscribe URL", with: ""
      fill_in "After Confirm URL", with: ""
      click_button "Save Changes"

      expect(page).to have_text("Redirect settings updated successfully")
      
      newsletter.reload
      expect(newsletter.redirect_after_subscribe).to be_blank
      expect(newsletter.redirect_after_confirm).to be_blank
    end

    it "persists URLs between page loads" do
      newsletter.update!(
        redirect_after_subscribe: "https://example.com/thank-you",
        redirect_after_confirm: "https://example.com/welcome"
      )

      visit embedding_settings_path(slug: newsletter.slug)

      expect(page).to have_field("After Subscribe URL", with: "https://example.com/thank-you")
      expect(page).to have_field("After Confirm URL", with: "https://example.com/welcome")
    end

    it "requires authentication" do
      sign_out
      visit embedding_settings_path(slug: newsletter.slug)
      expect(page).to have_current_path(new_user_session_path)
    end
  end
end