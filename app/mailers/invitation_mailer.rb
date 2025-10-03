class InvitationMailer < ApplicationMailer
  layout "base_mailer"

  def team_invitation
    @invitation = params[:invitation]
    @newsletter = @invitation.newsletter
    @invited_by = @invitation.invited_by
    @accept_url = invitation_url_for(token: @invitation.token)

    mail(
      to: @invitation.email,
      from: accounts_address,
      subject: "You've been invited to join #{@newsletter.title}"
    )
  end

  private

  def invitation_url_for(token:)
    Rails.application.routes.url_helpers.invitation_url(
      token: token,
      host: AppConfig.get("PICO_HOST", "localhost:3000")
    )
  end
end
