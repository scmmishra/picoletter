require "rails_helper"

RSpec.describe Newsletters::Settings::ApiController, type: :controller do
  let(:newsletter) { create(:newsletter) }

  before do
    sign_in(newsletter.user)
  end

  describe "POST #generate_token" do
    it "creates an API token when one does not exist" do
      expect {
        post :generate_token, params: { slug: newsletter.slug }
      }.to change(ApiToken, :count).by(1)

      expect(response).to redirect_to(settings_api_path(slug: newsletter.slug))
      expect(flash[:notice]).to eq("API token generated.")
    end

    it "does not create a duplicate API token" do
      create(:api_token, newsletter: newsletter)

      expect {
        post :generate_token, params: { slug: newsletter.slug }
      }.not_to change(ApiToken, :count)

      expect(response).to redirect_to(settings_api_path(slug: newsletter.slug))
      expect(flash[:alert]).to eq("A token already exists. Rotate it instead.")
    end
  end

  describe "PATCH #rotate_token" do
    let!(:token) { create(:api_token, newsletter: newsletter) }

    it "regenerates the selected token" do
      previous_value = token.token

      patch :rotate_token, params: { slug: newsletter.slug, token_id: token.id }

      expect(response).to redirect_to(settings_api_path(slug: newsletter.slug))
      expect(flash[:notice]).to eq("API token rotated.")
      expect(token.reload.token).not_to eq(previous_value)
      expect(token.token).to start_with("pcltr_")
    end
  end
end
