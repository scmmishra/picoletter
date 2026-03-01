require "rails_helper"

RSpec.describe ActiveStorage::Service::S3Service do
  describe "#url" do
    let(:test_key) { "posts/test-image.png" }
    let(:service) do
      described_class.new(
        bucket: "demo",
        access_key_id: "x",
        secret_access_key: "y",
        region: "us-east-1",
        endpoint: "https://s3.us-east-1.amazonaws.com",
        public: true
      )
    end

    context "when R2__PUBLIC_DOMAIN is not set" do
      it "falls back to default S3 URL generation" do
        with_env("R2__PUBLIC_DOMAIN", nil) do
          url = service.url(test_key)

          expect(url).to include(test_key)
          expect(url).to include("s3.us-east-1.amazonaws.com")
        end
      end
    end

    context "when R2__PUBLIC_DOMAIN is set" do
      it "returns a custom public domain URL" do
        with_env("R2__PUBLIC_DOMAIN", "cdn.example.com") do
          expect(service.url(test_key)).to eq("https://cdn.example.com/#{test_key}")
        end
      end
    end
  end

  def with_env(key, value)
    original_value = ENV[key]
    had_key = ENV.key?(key)

    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end

    yield
  ensure
    if had_key
      ENV[key] = original_value
    else
      ENV.delete(key)
    end
  end
end
