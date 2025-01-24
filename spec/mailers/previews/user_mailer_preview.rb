# Preview all emails at http://localhost:3000/rails/mailers/user_mailer_mailer
class UserMailerPreview < ActionMailer::Preview
  def verify
    UserMailer.verify(User.first)
  end
end
