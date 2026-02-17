class Newsletters::Settings::TeamController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action -> { authorize_permission!(:team, :read) }, only: [ :index ]
  before_action -> { authorize_permission!(:team, :write) }, only: [ :invite, :destroy, :update_role, :destroy_invitation ]

  def index
    @memberships = @newsletter.memberships.includes(:user)
    @members_without_owners = @memberships.where.not(user_id: @newsletter.user_id)
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

    if @membership.user_id == @newsletter.user_id
      redirect_to settings_team_path(slug: @newsletter.slug),
                  alert: "You cannot remove the owner's membership."
      return
    end

    if @membership.destroy
      redirect_to settings_team_path(slug: @newsletter.slug),
                  notice: "Team member removed successfully."
    else
      redirect_to settings_team_path(slug: @newsletter.slug),
                  alert: "Failed to remove team member."
    end
  end

  def update_role
    @membership = @newsletter.memberships.find(params[:id])

    if @membership.user_id == @newsletter.user_id
      redirect_to settings_team_path(slug: @newsletter.slug),
                  alert: "You cannot change the owner's role."
      return
    end

    if @membership.update(role: role_params[:role])
      redirect_to settings_team_path(slug: @newsletter.slug),
                  notice: "Role updated successfully."
    else
      redirect_to settings_team_path(slug: @newsletter.slug),
                  alert: "Failed to update role: #{@membership.errors.full_messages.join(', ')}"
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


  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end

  def role_params
    params.require(:membership).permit(:role)
  end

  def authorize_permission!(permission, access_type = :read)
    unless @newsletter.can_access?(permission, access_type)
      redirect_to profile_settings_path(slug: @newsletter.slug),
                  alert: "You don't have permission to access that section."
      nil
    end
  end
end
