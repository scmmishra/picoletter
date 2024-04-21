class Newsletters::SubscribersController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated, only: [ :index ]
  before_action :set_newsletter, only: [ :index ]

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
    @newsletter = Newsletter.from_slug(params[:slug])

    decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: "HS256" })
    subscriber_id = decoded_token.first["sub"]
    subscriber = @newsletter.subscribers.find(subscriber_id)
    subscriber.unsubscribe!
    # Log the unsubscribe activity
    Rails.logger.info("Subscriber #{subscriber.id} unsubscribed from newsletter #{@newsletter.id}")
    render :unsubscribed, layout: "application"
  rescue JWT::ExpiredSignature, JWT::DecodeError, ActiveRecord::RecordNotFound
    render :invalid, layout: "application"
  end

  private

  def set_newsletter
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
    redirect_to newsletter_url(Current.user.newsletters.first.slug) unless @newsletter
  end
end
