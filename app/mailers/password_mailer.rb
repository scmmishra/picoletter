class PasswordMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail to: @user.email, subject: "Reset your password."
  end
end
