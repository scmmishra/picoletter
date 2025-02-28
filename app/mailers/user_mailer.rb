class UserMailer < ApplicationMailer
  layout "base_mailer"

  def reset_password
    @user = params[:user]
    mail(to: @user.email, subject: "Reset your password.", from: accounts_address)
  end

  def verify_email
    @user = params[:user]
    @verification_url = edit_password_url(@user.generate_token_for(:verification))
    mail(to: @user.email, subject: "Welcome to Picoletter - just one more step!", from: accounts_address)
  end
end
