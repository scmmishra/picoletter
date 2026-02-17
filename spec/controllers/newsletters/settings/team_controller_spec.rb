require "rails_helper"

RSpec.describe Newsletters::Settings::TeamController, type: :controller do
  let(:newsletter) { create(:newsletter) }
  let(:owner) { newsletter.user }
  let(:administrator) { create(:user) }
  let(:editor) { create(:user) }
  let!(:admin_membership) { create(:membership, newsletter: newsletter, user: administrator, role: :administrator) }
  let!(:editor_membership) { create(:membership, newsletter: newsletter, user: editor, role: :editor) }

  before do
    allow(controller).to receive(:default_url_options).and_return(host: "test.host")
  end

  describe "GET #index" do
    context "when user has team read permissions" do
      it "renders successfully" do
        sign_in(editor)

        get :index, params: { slug: newsletter.slug }

        expect(response).to have_http_status(:success)
        expect(controller.instance_variable_get(:@memberships)).to include(admin_membership, editor_membership)
      end
    end

    context "when user lacks team permissions" do
      it "redirects away from the newsletter" do
        unauthorized_user = create(:user)
        sign_in(unauthorized_user)

        expect_any_instance_of(Newsletter).not_to receive(:invite_member)

        get :index, params: { slug: newsletter.slug }

        expect(response).to be_redirect
      end
    end
  end

  describe "POST #invite" do
    let(:invitation_params) do
      {
        slug: newsletter.slug,
        invitation: {
          email: "teammate@example.com",
          role: "editor"
        }
      }
    end

    before do
      sign_in(administrator)
    end

    it "creates an invitation and redirects with notice" do
      mailer = double(deliver_now: true)
      allow(InvitationMailer).to receive(:with).and_return(double(team_invitation: mailer))

      expect {
        post :invite, params: invitation_params
      }.to change(Invitation, :count).by(1)

      expect(response).to redirect_to(settings_team_path(slug: newsletter.slug))
      expect(flash[:notice]).to eq("Invitation sent to teammate@example.com.")
    end

    it "handles errors gracefully" do
      allow_any_instance_of(Newsletter).to receive(:invite_member)
        .and_raise(Newsletter::InvitationError, "Something went wrong")

      post :invite, params: invitation_params

      expect(response).to redirect_to(settings_team_path(slug: newsletter.slug))
      expect(flash[:alert]).to eq("Something went wrong")
    end

    it "prevents editors from inviting members" do
      sign_in(editor)

      post :invite, params: invitation_params

      expect(response).to redirect_to(settings_profile_path(slug: newsletter.slug))
      expect(flash[:alert]).to eq("You don't have permission to access that section.")
    end
  end

  describe "DELETE #destroy" do
    let!(:membership) { create(:membership, newsletter: newsletter, role: :editor) }

    before do
      sign_in(administrator)
    end

    it "removes the membership" do
      expect {
        delete :destroy, params: { slug: newsletter.slug, id: membership.id }
      }.to change(Membership, :count).by(-1)

      expect(response).to redirect_to(settings_team_path(slug: newsletter.slug))
      expect(flash[:notice]).to eq("Team member removed successfully.")
    end

    it "shows an alert if destroy fails" do
      allow_any_instance_of(Membership).to receive(:destroy).and_return(false)

      delete :destroy, params: { slug: newsletter.slug, id: membership.id }

      expect(response).to redirect_to(settings_team_path(slug: newsletter.slug))
      expect(flash[:alert]).to eq("Failed to remove team member.")
    end
  end

  describe "PATCH #update_role" do
    let!(:membership) { create(:membership, newsletter: newsletter, role: :editor) }

    before do
      sign_in(administrator)
    end

    it "updates the membership role" do
      patch :update_role, params: {
        slug: newsletter.slug,
        id: membership.id,
        membership: { role: "administrator" }
      }

      expect(response).to redirect_to(settings_team_path(slug: newsletter.slug))
      expect(flash[:notice]).to eq("Role updated successfully.")
      expect(membership.reload.role).to eq("administrator")
    end

    it "prevents changing the owner's role" do
      owner_membership = newsletter.memberships.find_by(user: owner)

      patch :update_role, params: {
        slug: newsletter.slug,
        id: owner_membership.id,
        membership: { role: "editor" }
      }

      expect(response).to redirect_to(settings_team_path(slug: newsletter.slug))
      expect(flash[:alert]).to eq("You cannot change the owner's role.")
      expect(owner_membership.reload.role).to eq("administrator")
    end

    it "shows an alert when update fails" do
      allow_any_instance_of(Membership).to receive(:update).and_return(false)
      allow_any_instance_of(Membership).to receive_message_chain(:errors, :full_messages).and_return([ "Role is invalid" ])

      patch :update_role, params: {
        slug: newsletter.slug,
        id: membership.id,
        membership: { role: "administrator" }
      }

      expect(response).to redirect_to(settings_team_path(slug: newsletter.slug))
      expect(flash[:alert]).to eq("Failed to update role: Role is invalid")
    end
  end

  describe "DELETE #destroy_invitation" do
    let!(:invitation) do
      create(
        :invitation,
        newsletter: newsletter,
        invited_by: owner,
        email: "teammate@example.com",
        role: :editor,
        token: SecureRandom.hex(8),
        accepted_at: nil
      )
    end

    before do
      sign_in(administrator)
    end

    it "destroys the invitation" do
      expect {
        delete :destroy_invitation, params: { slug: newsletter.slug, id: invitation.id }
      }.to change(Invitation, :count).by(-1)

      expect(response).to redirect_to(settings_team_path(slug: newsletter.slug))
      expect(flash[:notice]).to eq("Invitation cancelled.")
    end

    it "shows an alert when destroy fails" do
      allow_any_instance_of(Invitation).to receive(:destroy).and_return(false)

      delete :destroy_invitation, params: { slug: newsletter.slug, id: invitation.id }

      expect(response).to redirect_to(settings_team_path(slug: newsletter.slug))
      expect(flash[:alert]).to eq("Failed to cancel invitation.")
    end
  end
end
