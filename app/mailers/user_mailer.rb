class UserMailer < ApplicationMailer
  layout "base_mailer"

  def verify(user)
    @user = user
    @confirmation_url = "https://shivam.dev"
    mail(to: @user.email, subject: "Verify your email.", from: accounts_address)
  end
end
