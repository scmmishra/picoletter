require "rails_helper"

RSpec.describe Api::Documentation do
  describe ".endpoints" do
    subject(:endpoints) { described_class.endpoints(base_url: "https://example.test") }

    it "returns OpenAPI operations as endpoint docs" do
      create_endpoint = endpoints.find { |endpoint| endpoint[:method] == "POST" && endpoint[:path] == "/api/v1/subscribers" }

      expect(create_endpoint).to be_present
      expect(create_endpoint[:title]).to eq("Add a subscriber")
      expect(create_endpoint[:samples]).to be_present
      expect(create_endpoint[:samples].first[:code]).to include("https://example.test/api/v1/subscribers")
    end

    it "extracts parameters from both query/path and request body schemas" do
      list_endpoint = endpoints.find { |endpoint| endpoint[:method] == "GET" && endpoint[:path] == "/api/v1/subscribers" }
      update_endpoint = endpoints.find { |endpoint| endpoint[:method] == "PATCH" && endpoint[:path] == "/api/v1/subscribers/{id}" }

      expect(list_endpoint[:params].map { |param| param[:name] }).to include("status", "label", "page", "per_page")
      expect(update_endpoint[:params].map { |param| param[:name] }).to include("id", "full_name", "notes", "labels")
    end

    it "renders success response examples as pretty JSON strings" do
      endpoint = endpoints.find { |item| item[:method] == "GET" && item[:path] == "/api/v1/subscribers/counts" }

      expect(endpoint[:response]).to be_present
      parsed = JSON.parse(endpoint[:response])
      expect(parsed["total"]).to eq(150)
      expect(parsed["verified"]).to eq(120)
    end
  end
end
