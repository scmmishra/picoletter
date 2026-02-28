require "rails_helper"

RSpec.describe PasswordsController, type: :controller do
  before do
    request.host = "custom-domain.test"
    allow(controller).to receive(:default_url_options).and_return(host: "picoletter.test")
  end

  describe "GET #edit" do
    it "redirects invalid tokens without raising an open redirect error" do
      expect {
        get :edit, params: { token: "invalid_token" }
      }.not_to raise_error

      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to eq("Password reset link is invalid or has expired.")
    end
  end

  describe "PATCH #update" do
    it "redirects mismatched passwords without raising an open redirect error" do
      user = create(:user, email: "unique_#{SecureRandom.hex}@example.com", password: "oldpassword123")
      token = user.password_reset_token

      expect {
        patch :update, params: {
          token: token,
          password: "newpassword123",
          password_confirmation: "differentpassword"
        }
      }.not_to raise_error

      expect(response).to redirect_to(edit_password_path(token))
      expect(flash[:notice]).to eq("Passwords did not match.")
    end
  end
end
