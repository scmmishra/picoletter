require "rails_helper"

RSpec.describe SES::EmailService do
  let(:ses_client) do
    Aws::SESV2::Client.new(
      stub_responses: true,
      region: "us-east-1",
      credentials: Aws::Credentials.new("stub-key", "stub-secret")
    )
  end
  let(:service) { described_class.new }

  before do
    allow(AppConfig).to receive(:get).and_call_original
    allow(AppConfig).to receive(:get!).and_call_original
    allow(AppConfig).to receive(:get).with("AWS_REGION", BaseAwsService::REGION).and_return("us-east-1")
    allow(AppConfig).to receive(:get!).with("AWS_ACCESS_KEY_ID").and_return("stub-key")
    allow(AppConfig).to receive(:get!).with("AWS_SECRET_ACCESS_KEY").and_return("stub-secret")
    allow(AppConfig).to receive(:get).with("AWS_SES_CONFIGURATION_SET").and_return("Picoletter")
    allow(Aws::SESV2::Client).to receive(:new).and_return(ses_client)
    ses_client.stub_responses(:send_email, { message_id: "ses-message-id-1" })
  end

  describe "#send" do
    let(:base_params) do
      {
        to: [ "reader@example.com" ],
        from: "author@mail.picoletter.com",
        reply_to: "reply@example.com",
        subject: "Hello from Picoletter",
        html: "<p>Hello</p>",
        text: "Hello",
        headers: { "X-Newsletter-id" => "newsletter-1" }
      }
    end

    it "includes tenant_name when provided" do
      response = service.send(base_params.merge(tenant_name: "tenant-1"))

      expect(response.message_id).to eq("ses-message-id-1")
      request = ses_client.api_requests.last
      expect(request[:operation_name]).to eq(:send_email)
      expect(request[:params][:tenant_name]).to eq("tenant-1")
      expect(request[:params][:configuration_set_name]).to eq("Picoletter")
    end

    it "omits tenant_name when not provided" do
      service.send(base_params)

      request = ses_client.api_requests.last
      expect(request[:params]).not_to have_key(:tenant_name)
      expect(request[:params][:configuration_set_name]).to eq("Picoletter")
    end
  end
end
