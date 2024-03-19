class Auth::SessionsController < ApplicationController
  before_action :ensure_authenticated, only: [ :destroy ]
  before_action :resume_session_if_present, only: [ :new ]

  def new
    if Current.user.present?
      redirect_to_newsletter_home
    else
      render :new
    end
  end

  def create
    if user = User.active.authenticate_by(email: params[:email], password: params[:password])
      start_new_session_for user
      redirect_to_newsletter_home
    else
      render_rejection :unauthorized
    end
  end

  def destroy
    session = find_session_by_cookie
    session.destroy
    redirect_to auth_login_path, notice: "Logged out successfully."
  end

  private

  def render_rejection(status)
    flash.now[:alert] = "Invalid email or password. Please try again."
    render :new, status: status
  end
end
