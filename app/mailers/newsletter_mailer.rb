class NewsletterMailer < ApplicationMailer
  layout "newsletter_mailer"

  def broken_dns_records
    @newsletter = params[:newsletter]
    @user = @newsletter.user

    subject = "Broken DNS records for your newsletter"
    recipient = @newsletter.user.email

    mail(to: recipient, subject: subject, from: notify_address)
  end
end
