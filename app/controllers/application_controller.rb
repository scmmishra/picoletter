class ApplicationController < ActionController::Base
  include RateLimiter

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

  def redirect_to_newsletter_home
    has_newsletter = Current.user.newsletters.count > 0
    redirect_to has_newsletter ? posts_url(Current.user.newsletters.first.slug) : new_newsletter_url
  end
end
