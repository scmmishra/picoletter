class Newsletters::Settings::TeamController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action -> { authorize_permission!(:team, :read) }, only: [ :index ]
  before_action -> { authorize_permission!(:team, :write) }, only: [ :invite, :destroy ]

  def index
    @memberships = @newsletter.memberships.includes(:user)
    @invitations = @newsletter.invitations.pending.includes(:invited_by)
  end

  def invite
    service = TeamInvitationService.new(
      newsletter: @newsletter,
      email: invitation_params[:email],
      role: invitation_params[:role],
      invited_by: Current.user
    )

    invitation = service.call
    redirect_to settings_team_path(slug: @newsletter.slug),
                notice: "Invitation sent to #{invitation.email}."
  rescue TeamInvitationService::AlreadyMemberError => e
    redirect_to settings_team_path(slug: @newsletter.slug), alert: e.message
  rescue TeamInvitationService::ExistingInvitationError => e
    redirect_to settings_team_path(slug: @newsletter.slug), alert: e.message
  rescue TeamInvitationService::ValidationError => e
    redirect_to settings_team_path(slug: @newsletter.slug), alert: e.message
  end

  def destroy
    @membership = @newsletter.memberships.find(params[:id])

    if @membership.destroy
      redirect_to settings_team_path(slug: @newsletter.slug),
                  notice: "Team member removed successfully."
    else
      redirect_to settings_team_path(slug: @newsletter.slug),
                  alert: "Failed to remove team member."
    end
  end

  def destroy_invitation
    @invitation = @newsletter.invitations.find(params[:id])

    if @invitation.destroy
      redirect_to settings_team_path(slug: @newsletter.slug),
                  notice: "Invitation cancelled."
    else
      redirect_to settings_team_path(slug: @newsletter.slug),
                  alert: "Failed to cancel invitation."
    end
  end

  private

  def set_newsletter
    @newsletter = Newsletter.find_by(slug: params[:slug])
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end

  def authorize_permission!(permission, access_type = :read)
    unless @newsletter.can_access?(permission, access_type)
      redirect_to profile_settings_path(slug: @newsletter.slug),
                  alert: "You don't have permission to access that section."
    end
  end
end
