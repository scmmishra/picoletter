class PasswordMailer < ApplicationMailer
  layout "base_mailer"

  def reset(user)
    @user = user
    mail to: @user.email, subject: "Reset your password."
  end
end
