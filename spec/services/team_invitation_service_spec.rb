require "rails_helper"

RSpec.describe TeamInvitationService do
  let(:newsletter) { create(:newsletter) }
  let(:invited_by) { newsletter.user }
  let(:email) { "invitee@example.com" }
  let(:role) { "editor" }

  subject(:service) do
    described_class.new(
      newsletter: newsletter,
      email: email,
      role: role,
      invited_by: invited_by
    )
  end

  describe "#call" do
    context "with a brand new invitation" do
      it "persists the invitation and sends the email" do
        mailer = double(deliver_now: true)

        expect(InvitationMailer).to receive(:with) do |params|
          expect(params[:invitation]).to be_a(Invitation)
          expect(params[:invitation].email).to eq(email)
          expect(params[:invitation].role).to eq("editor")
          double(team_invitation: mailer)
        end

        expect { service.call }.to change(Invitation, :count).by(1)

        invitation = Invitation.last
        expect(invitation.newsletter).to eq(newsletter)
        expect(invitation.invited_by).to eq(invited_by)
        expect(invitation.role).to eq("editor")
        expect(invitation).to be_pending
      end
    end

    context "when the email already belongs to a member" do
      before do
        existing_user = create(:user, email: email)
        create(:membership, newsletter: newsletter, user: existing_user, role: :editor)
      end

      it "raises AlreadyMemberError" do
        expect { service.call }
          .to raise_error(described_class::AlreadyMemberError, /already a member/i)
      end
    end

    context "when a pending invitation already exists" do
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
        expect { service.call }
          .to raise_error(described_class::ExistingInvitationError, /already been sent/i)
      end
    end

    context "when validation fails" do
      let(:email) { "invalid-email" }

      before do
        allow(InvitationMailer).to receive(:with)
      end

      it "raises ValidationError and does not send mail" do
        expect { service.call }
          .to raise_error(described_class::ValidationError, /Failed to send invitation/i)

        expect(InvitationMailer).not_to have_received(:with)
      end
    end
  end
end
