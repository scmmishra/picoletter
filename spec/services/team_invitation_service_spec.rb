require "rails_helper"

RSpec.describe Newsletter, "#invite_member" do
  let(:newsletter) { create(:newsletter) }
  let(:invited_by) { newsletter.user }
  let(:email) { "invitee@example.com" }
  let(:role) { "editor" }

  describe "with a brand new invitation" do
    it "persists the invitation and sends the email" do
      mailer = double(deliver_now: true)

      expect(InvitationMailer).to receive(:with) do |params|
        expect(params[:invitation]).to be_a(Invitation)
        expect(params[:invitation].email).to eq(email)
        expect(params[:invitation].role).to eq("editor")
        double(team_invitation: mailer)
      end

      expect {
        newsletter.invite_member(email: email, role: role, invited_by: invited_by)
      }.to change(Invitation, :count).by(1)

      invitation = Invitation.last
      expect(invitation.newsletter).to eq(newsletter)
      expect(invitation.invited_by).to eq(invited_by)
      expect(invitation.role).to eq("editor")
      expect(invitation).to be_pending
    end
  end

  describe "when the email already belongs to a member" do
    before do
      existing_user = create(:user, email: email)
      create(:membership, newsletter: newsletter, user: existing_user, role: :editor)
    end

    it "raises AlreadyMemberError" do
      expect {
        newsletter.invite_member(email: email, role: role, invited_by: invited_by)
      }.to raise_error(Newsletter::AlreadyMemberError, /already a member/i)
    end
  end

  describe "when a pending invitation already exists" do
    before do
      create(
        :invitation,
        newsletter: newsletter,
        invited_by: invited_by,
        email: email,
        role: :editor,
        accepted_at: nil,
        created_at: 1.day.ago
      )
    end

    it "raises ExistingInvitationError" do
      expect {
        newsletter.invite_member(email: email, role: role, invited_by: invited_by)
      }.to raise_error(Newsletter::ExistingInvitationError, /already been sent/i)
    end
  end

  describe "when validation fails" do
    let(:email) { "invalid-email" }

    before do
      allow(InvitationMailer).to receive(:with)
    end

    it "raises InvitationError and does not send mail" do
      expect {
        newsletter.invite_member(email: email, role: role, invited_by: invited_by)
      }.to raise_error(Newsletter::InvitationError, /Failed to send invitation/i)

      expect(InvitationMailer).not_to have_received(:with)
    end
  end
end
