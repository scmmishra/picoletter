class SubscriptionMailer < ApplicationMailer
  layout "newsletter_mailer"

  def confirmation
    @subscriber = params[:subscriber]
    @newsletter = @subscriber.newsletter
    @confirmation_url = confirmation_url(@subscriber)
    subject = "Confirm your subscription to #{@newsletter.title}"
    mail(to: @subscriber.email, from: @newsletter.full_sending_address, subject: subject)
  end

  def confirmation_reminder
    @subscriber = params[:subscriber]
    @newsletter = @subscriber.newsletter
    @confirmation_url = confirmation_url(@subscriber)
    subject= "Reminder: Confirm your subscription to #{@newsletter.title}"
    mail(to: @subscriber.email, from: @newsletter.full_sending_address, subject: subject)
  end

  private

  def confirmation_url(subscriber)
    slug = subscriber.newsletter.slug
    token = subscriber.generate_token_for(:confirmation)

    Rails.application.routes.url_helpers.confirm_url(slug: slug, token: token)
  end
end
