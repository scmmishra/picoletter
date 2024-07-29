class Public::SubscribersController < ApplicationController
  layout "application"

  before_action :set_newsletter
  skip_before_action :verify_authenticity_token, only: [ :embed_subscribe ]

  def embed_subscribe
    subscriber = subscribe
    subscriber.update(created_via: "embed")

    redirect_to almost_there_path(@newsletter.slug, email: params[:email])
  end

  def public_subscribe
    subscriber = subscribe
    subscriber.update(created_via: "public")

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
    subscriber = Subscriber.decode_unsubscribe_token(token)
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
    render :invalid_unsubscribe
  end

  def confirm_subscriber
    token = params[:token]
    subscriber = Subscriber.decode_confirmation_token(token)

    subscriber.verify!
  rescue JWT::ExpiredSignature, JWT::DecodeError, ActiveRecord::RecordNotFound
    render :invalid_confirmation
  end

  private

  def set_newsletter
    @newsletter = Newsletter.from_slug(params[:slug])
  end
end
