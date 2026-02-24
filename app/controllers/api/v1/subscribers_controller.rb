class Api::V1::SubscribersController < Api::V1::BaseController
  before_action :check_permission!, only: :create

  rate_limit to: 30, within: 1.minute, by: -> { @api_token&.id || request.remote_ip }

  def create
    email = params[:email]
    name = params[:name]
    labels = params[:labels]

    unless email.present?
      render json: { error: "Email is required" }, status: :unprocessable_entity
      return
    end

    result = CreateSubscriberJob.perform_now(@newsletter.id, email, name, labels, "api", {})

    if result
      render json: { message: "Subscriber created", email: email }, status: :created
    else
      render json: { error: "Invalid email address" }, status: :unprocessable_entity
    end
  end

  def counts
    subscribers = @newsletter.subscribers

    render json: {
      total: subscribers.count,
      verified: subscribers.verified.count,
      unverified: subscribers.unverified.count,
      unsubscribed: subscribers.unsubscribed.count
    }
  end

  private

  def check_permission!
    unless @api_token.has_permission?("subscription")
      render json: { error: "Insufficient permissions" }, status: :forbidden
    end
  end
end
