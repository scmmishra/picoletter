require "rails_helper"

RSpec.describe InvitationsController, type: :controller do
  let(:newsletter) { create(:newsletter) }
  let(:owner) { newsletter.user }
  let(:invited_user) { create(:user, email: "invitee@example.com", verified_at: Time.current) }
  let(:invitation) do
    create(
      :invitation,
      newsletter: newsletter,
      invited_by: owner,
      email: invited_user.email,
      role: :editor,
      token: SecureRandom.hex(8),
      accepted_at: nil,
      expires_at: 2.days.from_now
    )
  end

  before do
    allow(controller).to receive(:default_url_options).and_return(host: "test.host")
  end

  describe "authentication" do
    it "redirects to login when user is not authenticated" do
      get :show, params: { token: invitation.token }

      expect(response).to redirect_to(auth_login_path)
      expect(flash[:alert]).to eq("Please log in to continue.")
    end
  end

  describe "GET #show" do
    before do
      sign_in(invited_user)
    end

    it "renders the invitation page" do
      get :show, params: { token: invitation.token }

      expect(response).to have_http_status(:success)
      expect(controller.instance_variable_get(:@newsletter)).to eq(newsletter)
      expect(controller.instance_variable_get(:@invited_by)).to eq(owner)
    end

    it "redirects when invitation belongs to another user" do
      invitation.update!(email: "different@example.com")

      get :show, params: { token: invitation.token }

      expect(response).to redirect_to(new_newsletter_path)
      expect(flash[:notice]).to eq("This invitation was issued to a different email.")
    end

    it "redirects when invitation is already accepted" do
      invitation.update!(accepted_at: Time.current)

      get :show, params: { token: invitation.token }

      expect(response).to redirect_to(posts_path(slug: newsletter.slug))
      expect(flash[:notice]).to eq("You've already accepted this invitation.")
    end

    it "redirects when invitation is expired" do
      invitation.update!(expires_at: 1.day.ago)

      get :show, params: { token: invitation.token }

      expect(response).to redirect_to(new_newsletter_path)
      expect(flash[:notice]).to eq("This invitation is no longer valid.")
    end
  end

  describe "POST #accept" do
    before do
      sign_in(invited_user)
    end

    it "accepts the invitation and creates membership" do
      expect {
        post :accept, params: { token: invitation.token }
      }.to change { newsletter.memberships.where(user: invited_user).count }.by(1)

      expect(response).to redirect_to(posts_path(slug: newsletter.slug))
      expect(flash[:notice]).to eq("You've successfully joined #{newsletter.title}!")
      expect(invitation.reload.accepted_at).to be_present
    end

    it "handles acceptance failure" do
      allow_any_instance_of(Invitation).to receive(:accept!).and_return(false)

      post :accept, params: { token: invitation.token }

      expect(response).to redirect_to(invitation_path(token: invitation.token))
      expect(flash[:alert]).to eq("Failed to accept invitation. Please try again.")
    end
  end

  describe "POST #ignore" do
    before do
      sign_in(invited_user)
    end

    it "stores token in session and redirects" do
      post :ignore, params: { token: invitation.token }

      expect(session[:ignored_invitation_tokens]).to include(invitation.token)
      expect(response).to redirect_to(new_newsletter_path)
      expect(flash[:notice]).to eq("Invitation dismissed for now.")
    end

    it "retains existing ignored tokens" do
      session[:ignored_invitation_tokens] = [ "existing" ]

      post :ignore, params: { token: invitation.token }

      expect(session[:ignored_invitation_tokens]).to contain_exactly("existing", invitation.token)
    end
  end

  describe "invalid tokens" do
    before do
      sign_in(invited_user)
    end

    it "redirects when invitation is not found" do
      get :show, params: { token: "missing" }

      expect(response).to redirect_to(new_newsletter_path)
      expect(flash[:notice]).to eq("This invitation is no longer valid.")
    end
  end
end
