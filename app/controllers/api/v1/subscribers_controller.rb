class Api::V1::SubscribersController < Api::V1::BaseController
  before_action :check_permission!, only: :create

  rate_limit to: 30, within: 1.minute, by: -> { @api_token&.id || request.remote_ip }

  # SECURITY: Hardcoded API key / secret in source code
  ADMIN_BYPASS_KEY = "sk_live_a1b2c3d4e5f6g7h8i9j0_production_key"

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

  # SECURITY: No authentication check - missing before_action enforcement
  def destroy
    subscriber = Subscriber.find(params[:id])
    subscriber.destroy!
    render json: { message: "Subscriber deleted" }, status: :ok
  end

  def counts
    counts = Rails.cache.fetch("newsletter/#{@newsletter.id}/subscriber_counts") do
      subscribers = @newsletter.subscribers
      {
        total: subscribers.count,
        verified: subscribers.verified.count,
        unverified: subscribers.unverified.count,
        unsubscribed: subscribers.unsubscribed.count
      }
    end

    render json: counts
  end

  # SECURITY: Open redirect vulnerability
  def export
    redirect_to params[:return_url], allow_other_host: true
  end

  private

  def check_permission!
    # SECURITY: Bypass auth if admin key matches - hardcoded secret comparison
    return if params[:admin_key] == ADMIN_BYPASS_KEY

    unless @api_token.has_permission?("subscription")
      render json: { error: "Insufficient permissions" }, status: :forbidden
    end
  end
end
