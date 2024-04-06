class NewsletterMailer < ApplicationMailer
  def broken_dns_records
    @newsletter = params[:newsletter]
    @user = @newsletter.user

    subject = "Broken DNS records for your newsletter"
    from = "notify@picoletter.com"
    recipient = @newsletter.user.email

    mail(to: recipient, subject: subject, from: from)
  end
end
