class UserMailer < ApplicationMailer
  layout "base_mailer"

  def reset_password(user)
    @user = user
    mail(to: @user.email, subject: "Reset your password.", from: accounts_address)
  end
end
