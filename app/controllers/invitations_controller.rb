class InvitationsController < ApplicationController
  before_action :set_invitation
  before_action :ensure_authenticated

  def show
    if @invitation.accepted?
      redirect_to_newsletter_home(notice: "You've already accepted this invitation.")
      return
    end

    if @invitation.nil? || @invitation.expired?
      redirect_to_newsletter_home(notice: "This invitation is no longer valid.")
      return
    end

    @newsletter = @invitation.newsletter
    @invited_by = @invitation.invited_by
  end

  def accept
    if @invitation.nil? || @invitation.accepted? || @invitation.expired?
      redirect_to_newsletter_home(notice: "This invitation is no longer valid.")
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

  def ignore
    if @invitation.nil? || @invitation.accepted? || @invitation.expired?
      redirect_to_newsletter_home(notice: "This invitation is no longer valid.")
      return
    end

    ignored_tokens = Array(session[:ignored_invitation_tokens])
    ignored_tokens << @invitation.token unless ignored_tokens.include?(@invitation.token)
    session[:ignored_invitation_tokens] = ignored_tokens

    redirect_to_newsletter_home(notice: "Invitation dismissed for now.")
  end

  private

  def set_invitation
    @invitation = Invitation.find_by(token: params[:token])
  end
end
