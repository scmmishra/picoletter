require "rails_helper"

RSpec.describe Newsletters::SettingsController, type: :controller do
  let(:user) { create(:user) }
  let(:newsletter) { create(:newsletter, user: user) }

  before do
    sign_in(user)
    allow(controller).to receive(:default_url_options).and_return(host: "test.host")
  end

  describe "#update_embedding" do
    it "updates redirect URLs successfully" do
      patch :update_embedding, params: {
        slug: newsletter.slug,
        newsletter: {
          redirect_after_subscribe: "https://example.com/thank-you",
          redirect_after_confirm: "https://example.com/welcome"
        }
      }

      newsletter.reload
      expect(newsletter.redirect_after_subscribe).to eq("https://example.com/thank-you")
      expect(newsletter.redirect_after_confirm).to eq("https://example.com/welcome")
      expect(response).to redirect_to(embedding_settings_path(slug: newsletter.slug))
      expect(flash[:notice]).to eq("Redirect settings updated successfully.")
    end

    it "handles invalid URLs" do
      patch :update_embedding, params: {
        slug: newsletter.slug,
        newsletter: {
          redirect_after_subscribe: "not-a-url",
          redirect_after_confirm: "also-not-a-url"
        }
      }

      expect(response).to redirect_to(embedding_settings_path(slug: newsletter.slug))
      expect(flash[:alert]).to eq("Failed to update redirect settings.")
    end

    it "allows clearing redirect URLs" do
      newsletter.update!(
        redirect_after_subscribe: "https://example.com/thank-you",
        redirect_after_confirm: "https://example.com/welcome"
      )

      patch :update_embedding, params: {
        slug: newsletter.slug,
        newsletter: {
          redirect_after_subscribe: "",
          redirect_after_confirm: ""
        }
      }

      newsletter.reload
      expect(newsletter.redirect_after_subscribe).to eq("")
      expect(newsletter.redirect_after_confirm).to eq("")
      expect(response).to redirect_to(embedding_settings_path(slug: newsletter.slug))
      expect(flash[:notice]).to eq("Redirect settings updated successfully.")
    end
  end

  describe "#destroy_connected_service" do
    let(:connected_service) { create(:connected_service, user: user, provider: "github") }

    context "when service deletion succeeds" do
      it "successfully deletes the connected service" do
        delete :destroy_connected_service, params: { id: connected_service.id, slug: newsletter.slug }

        expect(response).to redirect_to(profile_settings_path(slug: newsletter.slug))
        expect(flash[:notice]).to eq("Successfully disconnected Github.")
        expect(ConnectedService.exists?(connected_service.id)).to be false
      end
    end

    context "when service deletion fails" do
      before do
        allow_any_instance_of(ConnectedService).to receive(:destroy).and_return(false)
      end

      it "shows an error message" do
        delete :destroy_connected_service, params: { id: connected_service.id, slug: newsletter.slug }

        expect(response).to redirect_to(profile_settings_path(slug: newsletter.slug))
        expect(flash[:notice]).to eq("Could not disconnect Github.")
        expect(ConnectedService.exists?(connected_service.id)).to be true
      end
    end
  end
end
