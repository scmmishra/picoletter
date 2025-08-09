class InvitationsController < ApplicationController
  before_action :set_invitation
  before_action :ensure_authenticated

  def show
    if @invitation.nil? || @invitation.accepted? || @invitation.expired?
      redirect_to root_path, alert: "This invitation is no longer valid."
      return
    end

    @newsletter = @invitation.newsletter
    @invited_by = @invitation.invited_by
  end

  def accept
    if @invitation.nil? || @invitation.accepted? || @invitation.expired?
      redirect_to root_path, alert: "This invitation is no longer valid."
      return
    end

    if @invitation.accept!(Current.user)
      redirect_to posts_path(slug: @invitation.newsletter.slug),
                  notice: "You've successfully joined #{@invitation.newsletter.title}!"
    else
      redirect_to accept_invitation_path(token: params[:token]),
                  alert: "Failed to accept invitation. Please try again."
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by(token: params[:token])
  end
end
