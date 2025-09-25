require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "#team_invitation" do
    let(:newsletter) { create(:newsletter, title: "Dev Digest") }
    let(:invited_by) { newsletter.user }
    let(:generated_token) { "abc123token" }
    let(:invitation) do
      create(
        :invitation,
        newsletter: newsletter,
        invited_by: invited_by,
        email: "invitee@example.com",
        role: :editor,
        accepted_at: nil,
        expires_at: 2.days.from_now
      )
    end

    subject(:mail) { described_class.with(invitation: invitation).team_invitation }

    before do
      allow(SecureRandom).to receive(:urlsafe_base64).and_return(generated_token)
      invitation.reload
    end

    it "renders the headers" do
      expect(mail.to).to eq(["invitee@example.com"])
      expect(mail.from).to eq(["accounts@#{AppConfig.get("PICO_SENDING_DOMAIN", "picoletter.com")}"])
      expect(mail.subject).to eq("You've been invited to join Dev Digest")
    end

    it "assigns useful variables for the template" do
      expect(mail.body.encoded).to include("Dev Digest")
      expect(mail.body.encoded).to include(invited_by.name)
      expect(mail.body.encoded).to include(generated_token)
    end

    it "includes an actionable invitation URL" do
      host = AppConfig.get("DEFAULT_HOST", "localhost:3000")
      expect(mail.body.encoded).to include("http://#{host}/invitations/#{generated_token}")
    end
  end
end
