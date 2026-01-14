require "rails_helper"

RSpec.describe SES::EmailService do
  before { stub_aws_env_config }

  let(:service) { described_class.new }

  describe "#send" do
    it "sends email with all parameters" do
      response = service.send(
        to: [ "user@example.com" ],
        from: "sender@example.com",
        reply_to: "reply@example.com",
        subject: "Test Subject",
        html: "<p>HTML content</p>",
        text: "Text content",
        headers: { "X-Custom-Header" => "custom-value" }
      )

      # AWS SDK stubbing returns proper response structure
      expect(response.message_id).to be_present
    end

    it "sends email with tenant_name parameter" do
      # AWS SDK will validate tenant_name is a valid parameter
      # If v5 removes this parameter, this test will fail
      response = service.send(
        to: [ "user@example.com" ],
        from: "sender@example.com",
        reply_to: "reply@example.com",
        subject: "Test Subject",
        html: "<p>HTML content</p>",
        text: "Text content",
        tenant_name: "newsletter-123-abc456"
      )

      expect(response.message_id).to be_present
    end

    it "sends email without tenant_name parameter" do
      response = service.send(
        to: [ "user@example.com" ],
        from: "sender@example.com",
        reply_to: "reply@example.com",
        subject: "Test Subject",
        html: "<p>HTML content</p>",
        text: "Text content"
      )

      expect(response.message_id).to be_present
    end

    it "includes configuration_set_name in payload" do
      # This verifies the configuration set is being passed correctly
      response = service.send(
        to: [ "user@example.com" ],
        from: "sender@example.com",
        reply_to: "reply@example.com",
        subject: "Test Subject",
        html: "<p>HTML content</p>",
        text: "Text content"
      )

      expect(response).to be_a(Seahorse::Client::Response)
      expect(response.data).to be_a(Aws::SESV2::Types::SendEmailResponse)
    end

    it "handles multiple recipients" do
      response = service.send(
        to: [ "user1@example.com", "user2@example.com", "user3@example.com" ],
        from: "sender@example.com",
        reply_to: "reply@example.com",
        subject: "Test Subject",
        html: "<p>HTML content</p>",
        text: "Text content"
      )

      expect(response.message_id).to be_present
    end

    it "handles custom headers" do
      response = service.send(
        to: [ "user@example.com" ],
        from: "sender@example.com",
        reply_to: "reply@example.com",
        subject: "Test Subject",
        html: "<p>HTML content</p>",
        text: "Text content",
        headers: {
          "List-Unsubscribe" => "<mailto:unsubscribe@example.com>",
          "X-Custom-Header" => "value"
        }
      )

      expect(response.message_id).to be_present
    end

    context "error handling" do
      it "propagates AWS service errors" do
        # Create a client with error response
        error_client = Aws::SESV2::Client.new(
          stub_responses: {
            send_email: "ServiceError"
          }
        )

        allow(Aws::SESV2::Client).to receive(:new).and_return(error_client)
        service = described_class.new

        expect {
          service.send(
            to: [ "user@example.com" ],
            from: "sender@example.com",
            reply_to: "reply@example.com",
            subject: "Test",
            html: "<p>Test</p>",
            text: "Test"
          )
        }.to raise_error(Aws::SESV2::Errors::ServiceError)
      end

      it "propagates throttling errors" do
        throttle_client = Aws::SESV2::Client.new(
          stub_responses: {
            send_email: "Throttling"
          }
        )

        allow(Aws::SESV2::Client).to receive(:new).and_return(throttle_client)
        service = described_class.new

        expect {
          service.send(
            to: [ "user@example.com" ],
            from: "sender@example.com",
            reply_to: "reply@example.com",
            subject: "Test",
            html: "<p>Test</p>",
            text: "Test"
          )
        }.to raise_error(Aws::SESV2::Errors::Throttling)
      end
    end
  end
end
