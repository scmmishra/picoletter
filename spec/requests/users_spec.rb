require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /signup" do
    it "returns http success" do
      get signup_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /signup" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          name: "John Doe",
          email: "john@example.com",
          password: "password123"
        }
      end

      it "creates a new user" do
        expect {
          post signup_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "redirects to the newsletter home" do
        post signup_path, params: valid_params
        expect(response).to redirect_to(posts_url(User.last.newsletters.first.slug))
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          name: "",
          email: "john@example.com",
          password: "password123"
        }
      end

      it "does not create a new user" do
        expect {
          post signup_path, params: invalid_params
        }.not_to change(User, :count)
      end

      it "redirects to the signup page with a notice" do
        post signup_path, params: invalid_params
        expect(response).to redirect_to(signup_url)
        expect(flash[:notice]).to be_present
      end
    end
  end
end
