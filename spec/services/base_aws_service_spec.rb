require "rails_helper"

RSpec.describe BaseAwsService do
  describe "#initialize" do
    before { stub_aws_env_config }

    it "initializes SESV2 client" do
      service = described_class.new

      expect(service.ses_client).to be_a(Aws::SESV2::Client)
    end

    it "sets region from AppConfig" do
      service = described_class.new

      expect(service.region).to eq("us-east-1")
    end

    it "uses custom region when configured" do
      allow(AppConfig).to receive(:get).with("AWS_REGION", anything).and_return("eu-west-1")

      service = described_class.new

      expect(service.region).to eq("eu-west-1")
    end

    it "uses default region when not configured" do
      allow(AppConfig).to receive(:get).with("AWS_REGION", described_class::REGION).and_return("us-east-1")

      service = described_class.new

      expect(service.region).to eq("us-east-1")
    end

    it "reads AWS credentials from AppConfig" do
      # This verifies that AppConfig.get! is called for credentials
      expect(AppConfig).to receive(:get!).with("AWS_ACCESS_KEY_ID").and_return("test-key")
      expect(AppConfig).to receive(:get!).with("AWS_SECRET_ACCESS_KEY").and_return("test-secret")

      described_class.new
    end

    it "creates SESV2 client with credentials" do
      service = described_class.new

      # Verify the client is properly instantiated
      expect(service.ses_client).to be_present
      expect(service.ses_client.config.region).to eq("us-east-1")
    end
  end

  describe "client configuration" do
    before { stub_aws_env_config }

    it "client has correct region" do
      service = described_class.new

      expect(service.ses_client.config.region).to eq("us-east-1")
    end

    it "client is configured with stub_responses in test environment" do
      service = described_class.new

      # In test environment, AWS SDK should be configured to stub responses
      expect(Aws.config[:stub_responses]).to eq(true)
    end
  end

  describe "inheritance" do
    it "can be inherited by service classes" do
      # This verifies that child classes like SES::EmailService, SES::DomainService
      # can properly inherit from BaseAwsService
      expect(SES::EmailService.new).to be_a(BaseAwsService)
      expect(SES::DomainService.new("example.com")).to be_a(BaseAwsService)
      expect(SES::TenantService.new).to be_a(BaseAwsService)
    end
  end

  context "error handling" do
    it "raises error when AWS_ACCESS_KEY_ID is missing" do
      allow(AppConfig).to receive(:get!).with("AWS_ACCESS_KEY_ID").and_raise(KeyError.new("AWS_ACCESS_KEY_ID not found"))

      expect {
        described_class.new
      }.to raise_error(KeyError, /AWS_ACCESS_KEY_ID/)
    end

    it "raises error when AWS_SECRET_ACCESS_KEY is missing" do
      allow(AppConfig).to receive(:get!).with("AWS_ACCESS_KEY_ID").and_return("test-key")
      allow(AppConfig).to receive(:get!).with("AWS_SECRET_ACCESS_KEY").and_raise(KeyError.new("AWS_SECRET_ACCESS_KEY not found"))

      expect {
        described_class.new
      }.to raise_error(KeyError, /AWS_SECRET_ACCESS_KEY/)
    end
  end
end
