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
      start_new_session_for @user
      redirect_to_newsletter_home
    else
      redirect_to signup_url, notice: error_messages_for(@user.errors)
    end
  end

  private

  def user_params
    params.permit(:email, :password, :name)
  end

  def error_messages_for(errors)
    first = errors.first
    return "Something went wrong. Please try again." if first.attribute == :email && first.type == :taken

    errors.full_messages.to_sentence
  end
end
