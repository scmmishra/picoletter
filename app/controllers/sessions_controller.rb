class SessionsController < ApplicationController
  def new; end

  def create
    if user = User.active.authenticate_by(email: params[:email], password: params[:password])
      start_new_session_for user
      redirect_to_newsletter_home
    else
      render_rejection :unauthorized
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "Logged out successfully."
  end

  private

  def render_rejection(status)
    flash.now[:alert] = "Invalid email or password. Please try again."
    render :new, status: status
  end

  def redirect_to_newsletter_home
    has_newsletter = Current.user.newsletters.present?
    redirect_to has_newsletter ? newsletter_url(Current.user.newsletters.first) : new_newsletter_url
  end
end
