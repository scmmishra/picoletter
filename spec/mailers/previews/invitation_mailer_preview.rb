# Preview all emails at http://localhost:3000/rails/mailers/invitation_mailer
class InvitationMailerPreview < ActionMailer::Preview
  def team_invitation
    invitation = Invitation.pending.first || Invitation.new(
      email: "newmember@example.com",
      role: "editor",
      token: SecureRandom.urlsafe_base64(16),
      newsletter: Newsletter.first,
      invited_by: User.first,
      expires_at: 14.days.from_now
    )

    InvitationMailer.with(invitation: invitation).team_invitation
  end
end
