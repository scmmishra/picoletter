# AWS SDK stubbing configuration for tests
# This enables faithful dry testing by using AWS SDK's built-in stub responses
# instead of plain RSpec mocks. This approach validates method signatures and
# parameter structures against the actual SDK, catching breaking changes during upgrades.

RSpec.configure do |config|
  config.before(:each) do
    # Enable AWS SDK stubbing globally in tests
    # This prevents actual AWS API calls while still validating SDK usage
    Aws.config.update(
      stub_responses: true,
      region: "us-east-1",
      credentials: Aws::Credentials.new("fake-key", "fake-secret")
    )
  end
end

# Helper module for stubbing AppConfig AWS environment variables
module Helpers
  module AwsConfig
    def stub_aws_env_config
      allow(AppConfig).to receive(:get!).with("AWS_ACCESS_KEY_ID").and_return("fake-key")
      allow(AppConfig).to receive(:get!).with("AWS_SECRET_ACCESS_KEY").and_return("fake-secret")
      allow(AppConfig).to receive(:get).with("AWS_REGION", anything).and_return("us-east-1")
      allow(AppConfig).to receive(:get).with("AWS_SES_CONFIGURATION_SET").and_return("test-config-set")
    end
  end
end

RSpec.configure do |config|
  config.include Helpers::AwsConfig
end
