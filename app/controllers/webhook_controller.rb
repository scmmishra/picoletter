class WebhookController < ApplicationController
  protect_from_forgery with: :null_session

  def resend
    payload = request.body.read
    headers = request.headers
    secret = Rails.application.credentials.resend.webhook_secret
    wh = Svix::Webhook.new(secret)

    json = wh.verify(payload, headers)
    ProcessResendWebhookJob.perform_later(json)

    head :no_content
  rescue
    head :bad_request
  end
end
