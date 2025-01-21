class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def sns
    payload = JSON.parse(request.body.read)
    ProcessSNSWebhookJob.perform_now(payload)

    head :no_content
  rescue
    head :bad_request
  end
end
