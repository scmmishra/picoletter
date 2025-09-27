class ApplicationController < ActionController::Base
  include Pagy::Backend
  def ensure_authenticated
    session = find_session_by_cookie

    if session
      Current.user = session.user
    else
      redirect_to auth_login_path, alert: "Please log in to continue."
    end
  end

  def resume_session_if_present
    session = find_session_by_cookie
    Current.user = session.user if session.present?
  end

  private

  def find_session_by_cookie
    if token = cookies.signed[:session_token]
      Session.find_by(token: token)
    end
  end

  def start_new_session_for(user)
    session = user.sessions.create!
    authenticate_session session
  end

  def authenticate_session(session)
    Current.user = session.user
    cookies.signed.permanent[:session_token] = { value: session.token, httponly: true, same_site: :lax }
  end

  def verify_user
    Current.user.send_verification_email_once
    redirect_to verify_path, notice: "Please verify your email to continue."
  end

  def redirect_to_newsletter_home(notice: nil)
    return verify_user unless Current.user.verified?

    pending_invitation = pending_invitation_for_current_user
    if pending_invitation.present?
      # Visiting teams invites takes priority even if the user already operates other newsletters.
      redirect_to invitation_path(token: pending_invitation.token), notice: notice
      return
    end

    newsletters = Current.user.newsletters

    if newsletters.none?
      redirect_to new_newsletter_path, notice: notice
      return
    end

    # Prefer the last opened newsletter cache, otherwise fall back to the first one available.
    last_opened_newsletter = Rails.cache.read("last_opened_newsletter_#{Current.user.id}")
    target_slug = last_opened_newsletter.presence || newsletters.first.slug

    redirect_to posts_path(target_slug), notice: notice
  end

  def pending_invitation_for_current_user
    return if Current.user.blank?

    scope = Invitation.pending
                        .for_email(Current.user.email)
                        .order(created_at: :desc)

    # Allow users to ignore specific invites without surfacing them again.
    ignored_tokens = Array(session[:ignored_invitation_tokens])
    scope = scope.where.not(token: ignored_tokens) if ignored_tokens.present?

    scope.first
  end
end
