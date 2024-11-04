class PasswordMailer < ApplicationMailer
  layout "base_mailer"

  def reset(user)
    @user = user
    mail(to: @user.email, subject: "Reset your password.", from: accounts_address)
  end
end
