class NewsletterMailer < ApplicationMailer
  layout "newsletter_mailer"

  def broken_dns_records
    @domain = params[:domain]
    @user = @domain.newsletter.user

    subject = "Broken DNS records for your domain #{@domain.name}"
    recipient = @user.email

    mail(to: recipient, subject: subject, from: notify_address)
  end
end
