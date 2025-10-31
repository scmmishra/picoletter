require "rails_helper"

RSpec.describe Billable, type: :model do
  let(:user) { create(:user, name: "Billing User", email: "billing@example.com") }
  let(:billing_endpoint) { user.send(:billing_endpoint) }
  let(:headers) do
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer secret-key"
    }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_API_KEY").and_return("secret-key")
  end

  describe "#init_customer" do
    let(:expected_body) do
      {
        id: user.id,
        name: user.name,
        email: user.email
      }.to_json
    end

    it "posts the subscriber details to the billing init endpoint" do
      response = double("HTTParty response")

      expect(HTTParty).to receive(:post)
        .with("#{billing_endpoint}/init", headers: headers, body: expected_body)
        .and_return(response)

      expect(user.init_customer).to eq(response)
    end

    it "propagates errors raised by HTTParty" do
      expect(HTTParty).to receive(:post)
        .with("#{billing_endpoint}/init", headers: headers, body: expected_body)
        .and_raise(SocketError)

      expect { user.init_customer }.to raise_error(SocketError)
    end
  end

  describe "#billing_manage_url" do
    it "fetches the portal url from the billing service" do
      response = instance_double(HTTParty::Response, parsed_response: { "customerPortalUrl" => "https://portal.example.com" })

      expect(HTTParty).to receive(:get)
        .with("#{billing_endpoint}/manage/#{user.id}", headers: headers)
        .and_return(response)

      expect(user.billing_manage_url).to eq("https://portal.example.com")
    end

    it "returns nil when the billing service omits the portal url" do
      response = instance_double(HTTParty::Response, parsed_response: {})

      expect(HTTParty).to receive(:get)
        .with("#{billing_endpoint}/manage/#{user.id}", headers: headers)
        .and_return(response)

      expect(user.billing_manage_url).to be_nil
    end

    it "raises when the billing service cannot be reached" do
      expect(HTTParty).to receive(:get)
        .with("#{billing_endpoint}/manage/#{user.id}", headers: headers)
        .and_raise(SocketError)

      expect { user.billing_manage_url }.to raise_error(SocketError)
    end
  end

  describe "#billing_checkout_url" do
    it "returns the checkout url from the billing service" do
      response = instance_double(HTTParty::Response, parsed_response: { "url" => "https://checkout.example.com" })

      expect(HTTParty).to receive(:get)
        .with("#{billing_endpoint}/checkout/#{user.id}", headers: headers)
        .and_return(response)

      expect(user.billing_checkout_url).to eq("https://checkout.example.com")
    end

    it "returns nil when the billing service omits the checkout url" do
      response = instance_double(HTTParty::Response, parsed_response: {})

      expect(HTTParty).to receive(:get)
        .with("#{billing_endpoint}/checkout/#{user.id}", headers: headers)
        .and_return(response)

      expect(user.billing_checkout_url).to be_nil
    end

    it "raises when the billing service cannot be reached" do
      expect(HTTParty).to receive(:get)
        .with("#{billing_endpoint}/checkout/#{user.id}", headers: headers)
        .and_raise(SocketError)

      expect { user.billing_checkout_url }.to raise_error(SocketError)
    end
  end

  describe "#update_meter" do
    let(:count) { 42 }
    let(:expected_body) do
      {
        id: user.id,
        count: count
      }.to_json
    end

    it "posts usage counts to the billing injest endpoint" do
      response = instance_double(HTTParty::Response)

      expect(HTTParty).to receive(:post)
        .with("#{billing_endpoint}/injest", headers: headers, body: expected_body)
        .and_return(response)

      expect(user.update_meter(count)).to eq(response)
    end

    it "propagates errors raised by HTTParty" do
      expect(HTTParty).to receive(:post)
        .with("#{billing_endpoint}/injest", headers: headers, body: expected_body)
        .and_raise(SocketError)

      expect { user.update_meter(count) }.to raise_error(SocketError)
    end
  end
end
