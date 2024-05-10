class Public::SubscribersController < ApplicationController
  layout "application"

  before_action :set_newsletter
  skip_before_action :verify_authenticity_token, only: [ :embed_subscribe ]

  def embed_subscribe
    subscriber = subscribe
    subscriber.update(created_via: "embed")

    redirect_to almost_there_path(@newsletter.slug, email: params[:email])
  end

  def almost_there
    @email = params[:email]
    return unless @email.present?

    @provider = EmailInformationService.new(@email)
    @search_url = @provider.search_url(sender: @newsletter.sending_from) if @provider.name.present?
  end

  def subscribe
    name = params[:name]
    email = params[:email]

    # check if subscriber with email is already present
    subscriber = @newsletter.subscribers.find_by(email: email)
    subscriber.update(full_name: name) if subscriber.present? && name.present?

    # if subscriber is not present, create new one
    subscriber ||= @newsletter.subscribers.create!(email: email, full_name: name)

    subscriber.send_confirmation_email unless subscriber.verified?
    subscriber
  end

  def unsubscribe
    token = params[:token]

    decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: "HS256" })
    subscriber_id = decoded_token.first["sub"]
    subscriber = @newsletter.subscribers.find(subscriber_id)
    subscriber.unsubscribe!
    # Log the unsubscribe activity
    Rails.logger.info("Subscriber #{subscriber.id} unsubscribed from newsletter #{@newsletter.id}")
    # if request is a get, render the layout, or respond with 200 and json ok if it is a post
    if request.post?
      render json: { ok: true }
    else
      render :unsubscribed
    end
  rescue JWT::ExpiredSignature, JWT::DecodeError, ActiveRecord::RecordNotFound
    render :invalid
  end

  def confirm_subscriber
    #
  end

  private

  def set_newsletter
    @newsletter = Newsletter.from_slug(params[:slug])
  end
end
