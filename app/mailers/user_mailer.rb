class UserMailer < ApplicationMailer
  layout "base_mailer"

  def reset_password
    @user = params[:user]
    mail(to: @user.email, subject: "Reset your password.", from: accounts_address)
  end
end
