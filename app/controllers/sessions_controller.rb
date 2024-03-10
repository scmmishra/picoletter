class SessionsController < ApplicationController
  def new; end

  def create
    if user = User.active.authenticate_by(email: params[:email], password: params[:password])
      start_new_session_for(user)
    else
      render_rejection :unauthorized
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "Logged out successfully."
  end

  private

  def start_new_session_for(user)
    user.sessions.create!.tap do |session|
      authenticated_as session
    end
  end

  def render_rejection(status)
    flash.now[:alert] = "Invalid email or password. Please try again."
    render :new, status: status
  end

  def authenticated_as(session)
    Current.user = session.user
    cookies.signed.permanent[:session_token] = { value: session.token, httponly: true, same_site: :lax }
  end
end
