class PostMailer < ApplicationMailer
  layout "base_mailer"

  def test_post(email, post)
    @post = post
    @newsletter = @post.newsletter

    mail(to: email, subject: "Test Email: #{@post.title}", from: @newsletter.full_sending_address)
  end
end
