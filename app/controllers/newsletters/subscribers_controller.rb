class Newsletters::SubscribersController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter

  def index
    page = params[:page] || 0
    status = params[:status] || "verified"

    @subscribers = @newsletter.subscribers
      .order(created_at: :desc)
      .page(params[:page] || 0)
      .where(status: status)
      .per(30)
  end

  def unsubscribe
    token = params[:token]

    begin
      decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: "HS256" })
      subscriber_id = decoded_token.first["sub"]
      subscriber = newsletter.subscribers.find(subscriber_id)
      subscriber.unsubscribe!
      # Log the unsubscribe activity
      Rails.logger.info("Subscriber #{subscriber.id} unsubscribed from newsletter #{newsletter.id}")
      redirect_to root_path, notice: "You have been unsubscribed successfully."
    rescue JWT::ExpiredSignature
      redirect_to root_path, alert: "Unsubscribe link has expired."
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      redirect_to root_path, alert: "Invalid unsubscribe link."
    end
  end

  private

  def set_newsletter
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
    redirect_to newsletter_url(Current.user.newsletters.first.slug) unless @newsletter
  end
end
