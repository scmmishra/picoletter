class InvitationsController < ApplicationController
  before_action :set_invitation
  before_action :ensure_authenticated
  before_action :ensure_invitation_present
  before_action :ensure_invitation_belongs_to_current_user
  before_action :ensure_invitation_active, only: [:show, :accept, :ignore]
  before_action :redirect_if_already_member, only: [:show, :accept, :ignore]

  def show
    session[:ignored_invitation_tokens] = session[:ignored_invitation_tokens].reject { |token| token == @invitation.token }

    @newsletter = @invitation.newsletter
    @invited_by = @invitation.invited_by
  end

  def accept
    if @invitation.accept!(Current.user)
      redirect_to posts_path(slug: @invitation.newsletter.slug),
                  notice: "You've successfully joined #{@invitation.newsletter.title}!"
    else
      redirect_to invitation_path(token: params[:token]),
                  alert: "Failed to accept invitation. Please try again."
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.warn("Invitation acceptance failed: #{e.class} - #{e.message}")

    redirect_to invitation_path(token: params[:token]),
                alert: "Failed to accept invitation. Please try again."
  end

  def ignore
    ignored_tokens = Array(session[:ignored_invitation_tokens])
    ignored_tokens << @invitation.token unless ignored_tokens.include?(@invitation.token)
    session[:ignored_invitation_tokens] = ignored_tokens

    redirect_to_newsletter_home(notice: "Invitation dismissed for now.")
  end

  private

  def set_invitation
    @invitation = Invitation.find_by(token: params[:token])
  end

  def ensure_invitation_present
    return if @invitation.present?

    redirect_to_newsletter_home(notice: "This invitation is no longer valid.")
    return
  end

  def ensure_invitation_belongs_to_current_user
    return if @invitation.email.casecmp?(Current.user.email)

    redirect_to_newsletter_home(notice: "This invitation was issued to a different email.")
    return
  end

  def ensure_invitation_active
    if @invitation.accepted?
      redirect_to posts_path(slug: @invitation.newsletter.slug),
                  notice: "You've already accepted this invitation."
      return
    end

    if @invitation.expired?
      redirect_to_newsletter_home(notice: "This invitation is no longer valid.")
      return
    end
  end

  def redirect_if_already_member
    return unless @invitation.newsletter.memberships.exists?(user: Current.user)

    redirect_to posts_path(slug: @invitation.newsletter.slug),
                notice: "You're already part of this newsletter."
  end
end
