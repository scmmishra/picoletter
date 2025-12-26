require 'rails_helper'

RSpec.describe SES::TenantService do
  let(:mock_ses_client) { double("Aws::SESV2::Client") }
  let(:mock_sts_client) { double("Aws::STS::Client") }
  let(:tenant_name) { "newsletter-123-abc456" }
  let(:config_set_name) { "picoletter-config" }
  let(:region) { "us-east-1" }
  let(:account_id) { "123456789012" }
  let(:service) { described_class.new }

  before do
    # Stub AWS credentials
    allow(AppConfig).to receive(:get!).with("AWS_ACCESS_KEY_ID").and_return("fake-key-id")
    allow(AppConfig).to receive(:get!).with("AWS_SECRET_ACCESS_KEY").and_return("fake-secret-key")
    allow(AppConfig).to receive(:get).with("AWS_REGION", anything).and_return(region)

    allow(Aws::SESV2::Client).to receive(:new).and_return(mock_ses_client)
    allow(Aws::STS::Client).to receive(:new).and_return(mock_sts_client)
    allow(mock_sts_client).to receive(:get_caller_identity).and_return(
      double(account: account_id)
    )
  end

  describe "#create_tenant" do
    context "without config set" do
      it "creates a tenant without associating config set" do
        expect(mock_ses_client).to receive(:create_tenant).with(
          tenant_name: tenant_name
        )

        service.create_tenant(tenant_name)
      end
    end

    context "with config set" do
      it "creates a tenant and associates the config set" do
        config_set_arn = "arn:aws:ses:#{region}:#{account_id}:configuration-set/#{config_set_name}"

        expect(mock_ses_client).to receive(:create_tenant).with(
          tenant_name: tenant_name
        )
        expect(mock_ses_client).to receive(:create_tenant_resource_association).with(
          tenant_name: tenant_name,
          resource_arn: config_set_arn
        )

        service.create_tenant(tenant_name, config_set_name)
      end
    end

    context "when tenant creation fails" do
      it "raises the error" do
        allow(mock_ses_client).to receive(:create_tenant).and_raise(
          Aws::SESV2::Errors::ServiceError.new("context", "error")
        )

        expect {
          service.create_tenant(tenant_name)
        }.to raise_error(Aws::SESV2::Errors::ServiceError)
      end
    end
  end

  describe "#delete_tenant" do
    it "deletes the tenant" do
      expect(mock_ses_client).to receive(:delete_tenant).with(
        tenant_name: tenant_name
      )

      service.delete_tenant(tenant_name)
    end
  end

  describe "#identity_arn" do
    it "returns the correct ARN format" do
      domain = "example.com"
      expected_arn = "arn:aws:ses:#{region}:#{account_id}:identity/#{domain}"

      expect(service.identity_arn(domain)).to eq(expected_arn)
    end
  end

  describe "#configuration_set_arn" do
    it "returns the correct ARN format" do
      expected_arn = "arn:aws:ses:#{region}:#{account_id}:configuration-set/#{config_set_name}"

      expect(service.configuration_set_arn(config_set_name)).to eq(expected_arn)
    end
  end

  describe "#associate_identity" do
    it "associates the identity with the tenant" do
      domain = "example.com"
      identity_arn = "arn:aws:ses:#{region}:#{account_id}:identity/#{domain}"

      expect(mock_ses_client).to receive(:create_tenant_resource_association).with(
        tenant_name: tenant_name,
        resource_arn: identity_arn
      )

      service.associate_identity(tenant_name, domain)
    end
  end

  describe "#disassociate_identity" do
    it "disassociates the identity from the tenant" do
      domain = "example.com"
      identity_arn = "arn:aws:ses:#{region}:#{account_id}:identity/#{domain}"

      expect(mock_ses_client).to receive(:delete_tenant_resource_association).with(
        tenant_name: tenant_name,
        resource_arn: identity_arn
      )

      service.disassociate_identity(tenant_name, domain)
    end

    it "does not raise error when resource not found" do
      domain = "example.com"
      allow(mock_ses_client).to receive(:delete_tenant_resource_association).and_raise(
        Aws::SESV2::Errors::NotFoundException.new("context", "not found")
      )

      expect {
        service.disassociate_identity(tenant_name, domain)
      }.not_to raise_error
    end
  end

  describe "#associate_configuration_set" do
    it "associates the configuration set with the tenant" do
      config_set_arn = "arn:aws:ses:#{region}:#{account_id}:configuration-set/#{config_set_name}"

      expect(mock_ses_client).to receive(:create_tenant_resource_association).with(
        tenant_name: tenant_name,
        resource_arn: config_set_arn
      )

      service.associate_configuration_set(tenant_name, config_set_name)
    end
  end

  describe "#disassociate_configuration_set" do
    it "disassociates the configuration set from the tenant" do
      config_set_arn = "arn:aws:ses:#{region}:#{account_id}:configuration-set/#{config_set_name}"

      expect(mock_ses_client).to receive(:delete_tenant_resource_association).with(
        tenant_name: tenant_name,
        resource_arn: config_set_arn
      )

      service.disassociate_configuration_set(tenant_name, config_set_name)
    end

    it "does not raise error when resource not found" do
      allow(mock_ses_client).to receive(:delete_tenant_resource_association).and_raise(
        Aws::SESV2::Errors::NotFoundException.new("context", "not found")
      )

      expect {
        service.disassociate_configuration_set(tenant_name, config_set_name)
      }.not_to raise_error
    end
  end

  describe "#account_id" do
    it "fetches and caches the AWS account ID" do
      # First call should fetch from STS
      expect(service.send(:account_id)).to eq(account_id)

      # Subsequent calls should use cached value (only called once total in before block)
      expect(service.send(:account_id)).to eq(account_id)
      expect(mock_sts_client).to have_received(:get_caller_identity).once
    end
  end
end
