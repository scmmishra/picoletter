class InvitationMailer < ApplicationMailer
  def team_invitation(invitation)
    @invitation = invitation
    @newsletter = invitation.newsletter
    @invited_by = invitation.invited_by
    @accept_url = accept_invitation_url(token: @invitation.token)

    mail(
      to: @invitation.email,
      from: accounts_address,
      subject: "You've been invited to join #{@newsletter.title}"
    )
  end

  private

  def accept_invitation_url(token:)
    Rails.application.routes.url_helpers.accept_invitation_url(
      token: token,
      host: AppConfig.get("DEFAULT_HOST", "localhost:3000")
    )
  end
end
