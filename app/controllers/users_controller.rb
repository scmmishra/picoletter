class UsersController < ApplicationController
  include ActiveHashcash

  before_action :check_hashcash, only: :create unless Rails.env.test?
  before_action :resume_session_if_present, only: [ :new, :show_verify ]
  before_action :ensure_authenticated, only: [ :resend_verification_email, :show_verify ]
  before_action :set_require_invite_code, only: [ :new, :create ]
  before_action :check_invite_code, only: [ :create ]

  rate_limit to: 5, within: 5.minutes, only: :resend_verification_email
  rate_limit to: 5, within: 3.minutes, only: :create

  def new
    if Current.user.present?
      redirect_to_newsletter_home
    else
      render :new
    end
  end

  def resend_verification_email
    Current.user.send_verification_email
    redirect_to verify_path, notice: "Verification email resent."
  end

  def show_verify
    return redirect_to_newsletter_home if Current.user.verified?

    @provider = EmailInformationService.new(Current.user.email)
    sending_domain = AppConfig.get("PICO_SENDING_DOMAIN", "picoletter.com")
    @search_url = @provider.search_url(sender: "accounts@#{sending_domain}") if @provider.name.present?

    render :verify
  end

  def confirm_verification
    token = params[:token]
    user = User.find_by_token_for!(:verification, token)
    user.verify!
    start_new_session_for user
    redirect_to_newsletter_home notice: "Email verification successful."
  rescue => error
    if Current.user.present?
      redirect_to verify_path, notice: "Invalid verification token."
    else
      redirect_to auth_login_path, notice: "Invalid verification token."
    end
  end

  def create
    @user = User.new(user_params.except(:invite_code))

    if @user.save
      start_new_session_for @user
      return redirect_to_newsletter_home if @user.verified?

      @user.send_verification_email_once
      redirect_to verify_path
    else
      redirect_to signup_path, notice: error_messages_for(@user.errors)
    end
  end

  private

  def check_invite_code
    return unless @require_invite

    if user_params[:invite_code].blank?
      redirect_to signup_path, notice: "Please enter an invite code."
    elsif user_params[:invite_code] != AppConfig.get("INVITE_CODE")
      redirect_to signup_path, notice: "Invalid invite code"
    end
  end

  def set_require_invite_code
    @require_invite = AppConfig.get("INVITE_CODE").present?
  end

  def user_params
    params.permit(:email, :password, :name, :invite_code)
  end

  def error_messages_for(errors)
    first = errors.first
    return "Something went wrong. Please try again." if first.attribute == :email && first.type == :taken

    errors.full_messages.to_sentence
  end
end
