require 'rails_helper'

RSpec.describe ProcessResendWebhookJob, type: :job do
  let(:email) { create(:email, email_id: "10000", status: :sent) }
  let(:email_id) { email.email_id }
  let(:product) { email.product }

  describe "#perform" do
    context "when email is delivered" do
      let(:payload) do
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

      expect(email.reload.status).to eq("delivered")
    end
  end
end
