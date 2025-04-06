require "rails_helper"

RSpec.describe Newsletters::SettingsController, type: :controller do
  describe "#destroy_connected_service" do
    let(:user) { create(:user) }
    let(:newsletter) { create(:newsletter, user: user) }
    let(:connected_service) { create(:connected_service, user: user, provider: "github") }

    before do
      sign_in(user)
    end

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
