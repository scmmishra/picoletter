class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def sns
    payload = JSON.parse(request.body.read)
    ProcessSNSWebhookJob.perform_later(payload)

    head :no_content
  rescue JSON::ParserError => e
    Rails.error.report(e)
    head :bad_request
  rescue StandardError => e
    Rails.error.report(e, context: { body: payload })
    head :bad_request
  end
end
