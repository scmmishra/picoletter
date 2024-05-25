require 'rails_helper'

RSpec.describe ProcessResendWebhookJob, type: :job do
  let(:email) { create(:email, email_id: "10000", status: :sent) }
  let(:email_id) { email.email_id }

  let(:email_delivered_payload) do
    {
      "type" => "email.delivered",
      "created_at" => Time.current.iso8601,
      "data" => {
        "created_at" => Time.current.iso8601,
        "email_id" => email_id,
        "from" => "Acme <onboarding@mail.picoletter.com>",
        "to" => ["delivered@resend.dev"],
        "subject" => "Sending this example"
      }
    }
  end

  context "when email is delivered" do
    it "updates the status" do
      described_class.perform_now(email_delivered_payload)
      expect(email.reload.status).to eq("delivered")
    end
  end
end
