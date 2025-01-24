class UserMailer < ApplicationMailer
  layout "base_mailer"

  def verify(user)
    @user = user
    @confirmation_url = verify_url(@user.generate_token_for(:verification))
    mail(to: @user.email, subject: "Verify your email.", from: accounts_address)
  end
end
