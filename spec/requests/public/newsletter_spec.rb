require 'rails_helper'

RSpec.describe "Public::Newsletters", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/public/newsletter/show"
      expect(response).to have_http_status(:success)
    end
  end

end
