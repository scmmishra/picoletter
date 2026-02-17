require "rails_helper"

RSpec.describe EmailInformationService do
  let(:providers_data) do
    [
      {
        "name" => "Gmail",
        "url" => "https://gmail.com",
        "hosts" => [ "gmail.com" ],
        "search" => "https://mail.google.com/mail/u/0/#search/%{sender}+%{email}+after:%{timestamp}"
      },
      {
        "name" => "Yahoo",
        "url" => "https://yahoo.com",
        "hosts" => [ "yahoo.com", "yahoo.co.uk" ],
        "search" => "https://mail.yahoo.com/search?query=%{sender}+%{email}"
      }
    ]
  end

  before do
    allow(File).to receive(:read).and_return(providers_data.to_json)
  end

  describe "#initialize" do
    context "with a known provider email" do
      let(:service) { described_class.new("user@gmail.com") }

      it "sets the provider information" do
        expect(service.name).to eq("Gmail")
        expect(service.url).to eq("https://mail.google.com/")
      end
    end

    context "with an unknown provider email" do
      let(:service) { described_class.new("user@unknown.com") }

      it "does not set provider information" do
        expect(service.name).to be_nil
        expect(service.url).to be_nil
      end
    end

    context "with email from alternative host" do
      let(:service) { described_class.new("user@yahoo.co.uk") }

      it "finds the correct provider" do
        expect(service.name).to eq("Yahoo!")
        expect(service.url).to eq("https://mail.yahoo.com/")
      end
    end

    context "with uppercase email" do
      let(:service) { described_class.new("USER@GMAIL.COM") }

      it "handles case insensitivity" do
        expect(service.name).to eq("Gmail")
        expect(service.url).to eq("https://mail.google.com/")
      end
    end

    context "with invalid email format" do
      let(:service) { described_class.new("invalid-email") }

      it "does not set provider information" do
        expect(service.name).to be_nil
        expect(service.url).to be_nil
      end
    end
  end

  describe "PROVIDERS constant" do
    it "loads providers from YAML file" do
      providers = described_class::PROVIDERS
      expect(providers).to be_an(Array)
      expect(providers).not_to be_empty
      expect(providers.first).to have_key("name")
    end
  end

  describe "actual providers.yml validation" do
    let(:actual_providers) { described_class::PROVIDERS }

    it "contains valid YAML data" do
      expect { actual_providers }.not_to raise_error
      expect(actual_providers).to be_an(Array)
      expect(actual_providers).not_to be_empty
    end

    it "has valid provider structure" do
      actual_providers.each_with_index do |provider, index|
        expect(provider).to be_a(Hash), "Provider at index #{index} should be a hash"
        expect(provider).to have_key("name"), "Provider at index #{index} missing 'name'"
        expect(provider).to have_key("url"), "Provider at index #{index} missing 'url'"
        expect(provider).to have_key("hosts"), "Provider at index #{index} missing 'hosts'"
        expect(provider).to have_key("search"), "Provider at index #{index} missing 'search'"

        expect(provider["name"]).to be_a(String), "Provider '#{provider["name"]}' name should be string"
        expect(provider["name"]).not_to be_empty, "Provider at index #{index} name should not be empty"

        expect(provider["url"]).to be_a(String), "Provider '#{provider["name"]}' url should be string"
        expect(provider["url"]).to match(/\Ahttps?:\/\//), "Provider '#{provider["name"]}' url should be valid HTTP(S) URL"

        expect(provider["hosts"]).to be_an(Array), "Provider '#{provider["name"]}' hosts should be array"
        expect(provider["hosts"]).not_to be_empty, "Provider '#{provider["name"]}' hosts should not be empty"

        provider["hosts"].each do |host|
          expect(host).to be_a(String), "Host '#{host}' in provider '#{provider["name"]}' should be string"
          expect(host).not_to be_empty, "Host in provider '#{provider["name"]}' should not be empty"
          expect(host).not_to include("@"), "Host '#{host}' in provider '#{provider["name"]}' should not contain @"
        end

        expect(provider["search"]).to be_a(String), "Provider '#{provider["name"]}' search should be string"
        expect(provider["search"]).to match(/\Ahttps?:\/\//), "Provider '#{provider["name"]}' search should be valid HTTP(S) URL"
      end
    end

    it "has unique provider names" do
      names = actual_providers.map { |p| p["name"] }
      expect(names).to eq(names.uniq), "Provider names should be unique"
    end

    it "has unique hosts across all providers" do
      all_hosts = actual_providers.flat_map { |p| p["hosts"] }
      duplicates = all_hosts.group_by(&:itself).select { |_, v| v.size > 1 }.keys
      expect(duplicates).to be_empty, "Duplicate hosts found: #{duplicates.join(', ')}"
    end

    it "includes common email providers" do
      names = actual_providers.map { |p| p["name"] }
      expect(names).to include("Gmail")
      expect(names).to include("Yahoo!")
    end

    it "Gmail provider includes common Gmail hosts" do
      gmail_provider = actual_providers.find { |p| p["name"] == "Gmail" }
      expect(gmail_provider).to be_present
      expect(gmail_provider["hosts"]).to include("gmail.com")
      expect(gmail_provider["hosts"]).to include("googlemail.com")
    end
  end

  describe "#search_url" do
    let(:service) { described_class.new("user@gmail.com") }
    let(:sender) { "sender@example.com" }
    let(:current_time) { Time.zone.parse("2024-01-01 12:00:00") }

    before do
      allow(Time).to receive(:now).and_return(current_time)
    end

    it "generates search URL with proper URL encoding" do
      url = service.search_url(sender: sender)

      expect(url).to include("sender%40example.com")
      expect(url).to include("user%40gmail.com")
      expect(url).to include("newer_than%3A1h")
    end

    context "when sender is nil" do
      it "handles nil sender gracefully" do
        url = service.search_url(sender: nil)

        expect(url).to include("")
        expect(url).to include("user%40gmail.com")
      end
    end

    context "with special characters in email" do
      let(:service) { described_class.new("user+test@gmail.com") }

      it "properly encodes special characters" do
        url = service.search_url(sender: "sender+test@example.com")

        expect(url).to include("sender%2Btest%40example.com")
        expect(url).to include("user%2Btest%40gmail.com")
      end
    end
  end
end
