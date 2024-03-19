class UsersController < ApplicationController
  before_action :resume_session_if_present, only: [ :new ]

  def new
    if Current.user.present?
      redirect_to_newsletter_home
    else
      render :new
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # Handle successful signup, e.g., redirect to onboarding or login page
      redirect_to onboarding_path, notice: "Signup successful!"
    else
      # Handle signup errors
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
