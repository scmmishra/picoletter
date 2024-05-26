class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def resend
    payload = request.body.read
    headers = request.headers
    secret = AppConfig.get("RESEND__WEBHOOK_SECRET")
    wh = Svix::Webhook.new(secret)

    json = wh.verify(payload, headers)
    ProcessResendWebhookJob.perform_later(json)

    head :no_content
  rescue
    head :bad_request
  end
end
