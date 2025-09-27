require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user, verified_at: Time.now) }
  let(:valid_params) { { email: "test@example.com", password: "password123", name: "Test User" } }

  before do
    allow(AppConfig).to receive(:get).and_call_original
  end

  describe "GET #new" do
    context "when user is not logged in" do
      it "returns http success" do
        get :new
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is logged in" do
      before do
        allow(Current).to receive(:user).and_return(user)
      end

      it "redirects to newsletter home" do
        get :new
        expect(response).to redirect_to(new_newsletter_path)
      end

      it "redirects to pending invitation when available" do
        invitation = create(:invitation, email: user.email)

        get :new

        expect(response).to redirect_to(invitation_path(token: invitation.token))
      end
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      context "when invite code is not required" do
        before do
          allow(AppConfig).to receive(:get).with("INVITE_CODE").and_return(nil)
          allow(AppConfig).to receive(:get).with("VERIFY_SIGNUPS", true).and_return(true)
        end

        it "creates a new user" do
          expect {
            post :create, params: valid_params
          }.to change(User, :count).by(1)
        end

        it "starts a new session" do
          post :create, params: valid_params
          expect(cookies.signed[:session_token]).to be_present
        end
      end

      context "when invite code is required" do
        before do
          allow(AppConfig).to receive(:get).with("INVITE_CODE").and_return("secret123")
          allow(AppConfig).to receive(:get).with("VERIFY_SIGNUPS", true).and_return(true)
        end

        it "creates user with correct invite code" do
          expect {
            post :create, params: valid_params.merge(invite_code: "secret123")
          }.to change(User, :count).by(1)
        end

        it "rejects creation without invite code" do
          post :create, params: valid_params
          expect(response).to redirect_to(signup_path)
          expect(flash[:notice]).to eq("Please enter an invite code.")
        end

        it "rejects creation with invalid invite code" do
          post :create, params: valid_params.merge(invite_code: "wrong")
          expect(response).to redirect_to(signup_path)
          expect(flash[:notice]).to eq("Invalid invite code")
        end
      end
    end

    context "with invalid parameters" do
      it "redirects with error for invalid email" do
        post :create, params: valid_params.merge(email: "invalid")
        expect(response).to redirect_to(signup_path)
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe "GET #show_verify" do
    before do
      allow(Current).to receive(:user).and_return(user)
      sign_in(user)
    end

    context "when user is verified" do
      before do
        allow(user).to receive(:verified?).and_return(true)
      end

      it "redirects to newsletter home" do
        get :show_verify
        expect(response).to redirect_to(new_newsletter_path)
      end
    end

    context "when user is not verified" do
      before do
        allow(user).to receive(:verified?).and_return(false)
      end

      it "shows verification page" do
        get :show_verify
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST #resend_verification_email" do
    before do
      allow(Current).to receive(:user).and_return(user)
      sign_in(user)
    end

    it "resends verification email" do
      expect(user).to receive(:send_verification_email)
      post :resend_verification_email
      expect(response).to redirect_to(verify_path)
      expect(flash[:notice]).to eq("Verification email resent.")
    end
  end

  describe "GET #confirm_verification" do
    context "with valid token" do
      before do
        allow(User).to receive(:find_by_token_for!).and_return(user)
      end

      it "verifies the user" do
        expect(user).to receive(:verify!)
        get :confirm_verification, params: { token: "valid_token" }
        expect(response).to redirect_to(new_newsletter_path)
      end
    end

    context "with invalid token" do
      before do
        allow(User).to receive(:find_by_token_for!).and_raise(StandardError)
      end

      context "when user is logged in" do
        before do
          allow(Current).to receive(:user).and_return(user)
        end

        it "redirects to verify path" do
          get :confirm_verification, params: { token: "invalid_token" }
          expect(response).to redirect_to(verify_path)
          expect(flash[:notice]).to eq("Invalid verification token.")
        end
      end

      context "when user is not logged in" do
        it "redirects to login path" do
          get :confirm_verification, params: { token: "invalid_token" }
          expect(response).to redirect_to(auth_login_path)
          expect(flash[:notice]).to eq("Invalid verification token.")
        end
      end
    end
  end
end
