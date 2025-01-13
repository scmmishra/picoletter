require 'rails_helper'

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user) }

  describe "POST /passwords" do
    context "when email exists" do
      it "sends password reset instructions" do
        post passwords_path, params: { email: user.email }
        expect(response).to redirect_to(auth_login_path)
        follow_redirect!
        expect(response.body).to include("Password reset instructions sent (if user with that email address exists).")
      end
    end

    context "when email does not exist" do
      it "still redirects to login path" do
        post passwords_path, params: { email: "nonexistent@example.com" }
        expect(response).to redirect_to(auth_login_path)
        follow_redirect!
        expect(response.body).to include("Password reset instructions sent (if user with that email address exists).")
      end
    end
  end

  describe "PUT /passwords/:token" do
    let(:reset_token) { user.generate_reset_token }

    context "with valid token" do
      it "updates the password successfully" do
        put password_path(reset_token), params: { password: "newpassword", password_confirmation: "newpassword" }
        expect(response).to redirect_to(auth_login_path)
        follow_redirect!
        expect(response.body).to include("Password has been reset.")
      end
    end

    context "with invalid token" do
      it "redirects to new password path with alert" do
        put password_path("invalidtoken"), params: { password: "newpassword", password_confirmation: "newpassword" }
        expect(response).to redirect_to(new_password_path)
        follow_redirect!
        expect(response.body).to include("Password reset link is invalid or has expired.")
      end
    end

    context "with mismatched password and confirmation" do
      it "redirects to edit password path with notice" do
        put password_path(reset_token), params: { password: "newpassword", password_confirmation: "differentpassword" }
        expect(response).to redirect_to(edit_password_path(reset_token))
        follow_redirect!
        expect(response.body).to include("Passwords did not match.")
      end
    end
  end
end
