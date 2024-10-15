class PasswordsController < ApplicationController
  before_action :set_user_by_token, only: %i[ edit update ]
  throttle to: 5, within: 30.minute, only: [ :create ], block_bots: true

  def new
  end

  def create
    if user = User.find_by(email: params[:email])
      PasswordMailer.reset(user).deliver_later
    end

    redirect_to auth_login_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      redirect_to auth_login_path, notice: "Password has been reset."
    else
      redirect_to edit_password_url(params[:token]), notice: "Passwords did not match."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_url, alert: "Password reset link is invalid or has expired."
    end
end