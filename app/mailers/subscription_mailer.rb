class SubscriptionMailer < ApplicationMailer
  def confirmation
    @subscriber = params[:subscriber]
    @newsletter = @subscriber.newsletter
    @confirmation_url = confirmation_url(@subscriber)
    mail(to: @subscriber.email, from: @newsletter.full_sending_address, subject: "Confirm your subscription")
  end

  def confirmation_reminder(subscriber)
  end

  private

  def confirmation_url(subscriber)
    slug = subscriber.newsletter.slug
    token = subscriber.generate_confirmation_token

    Rails.application.routes.url_helpers.confirm_url(slug: slug, token: token)
  end
end
