# Preview all emails at http://localhost:3000/rails/mailers/user_mailer_mailer
class UserMailerPreview < ActionMailer::Preview
  def reset_password
    UserMailer.with(user: User.first).reset_password
  end

  def verify_email
    UserMailer.with(user: User.first).verify_email
  end
end
