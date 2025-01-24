class ApplicationController < ActionController::Base
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
    redirect_to show_verify_url unless Current.user.verified?

    has_newsletter = Current.user.newsletters.count > 0
    last_opened_newsletter = Rails.cache.read("last_opened_newsletter_#{Current.user.id}")

    if has_newsletter && last_opened_newsletter.present?
      redirect_to posts_url(last_opened_newsletter)
    elsif has_newsletter
      redirect_to posts_url(Current.user.newsletters.first.slug)
    else
      redirect_to new_newsletter_url
    end
  end
end
