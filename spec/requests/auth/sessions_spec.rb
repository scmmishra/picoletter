require 'rails_helper'

RSpec.describe "Auth::Sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /auth/login" do
    it "renders the login page" do
      get auth_login_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome back")
    end
  end

  describe "POST /auth/login" do
    context "with valid credentials" do
      it "logs in the user and redirects to the newsletter home" do
        post auth_login_path, params: { email: user.email, password: user.password }
        expect(response).to redirect_to(posts_url(user.newsletters.first.slug))
        follow_redirect!
        expect(response.body).to include("Logged in successfully")
      end
    end

    context "with invalid credentials" do
      it "renders the login page with an alert" do
        post auth_login_path, params: { email: user.email, password: "wrongpassword" }
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("Invalid email or password. Please try again.")
      end
    end
  end

  describe "DELETE /auth/logout" do
    before do
      post auth_login_path, params: { email: user.email, password: user.password }
    end

    it "logs out the user and redirects to the login page" do
      delete auth_logout_path
      expect(response).to redirect_to(auth_login_path)
      follow_redirect!
      expect(response.body).to include("Logged out successfully.")
    end
  end
end
