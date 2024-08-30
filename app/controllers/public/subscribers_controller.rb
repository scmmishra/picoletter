class Public::SubscribersController < ApplicationController
  layout "application"

  before_action :set_newsletter
  skip_before_action :verify_authenticity_token, only: [ :embed_subscribe ]

  throttle to: 10, within: 30.minute, only: [ :embed_subscribe, :public_subscribe ], block_bots: true

  def embed_subscribe
    return head :forbidden if AppConfig.get("DISABLE_EMBED_SUBSCRIBE")
    CreateSubscriberJob.perform_later(@newsletter.id, params[:email], params[:name], "embed")
    redirect_to almost_there_path(@newsletter.slug, email: params[:email])
  rescue => e
    Rails.logger.error(e)
    redirect_to newsletter_path(@newsletter.slug), notice: "Seems like you entered an invalid email. Please try again."
  end

  def public_subscribe
    CreateSubscriberJob.perform_later(@newsletter.id, params[:email], params[:name], "public")

    redirect_to almost_there_path(@newsletter.slug, email: params[:email])
  rescue => e
    Rails.logger.error(e)
    redirect_to newsletter_path(@newsletter.slug), notice: "Seems like you entered an invalid email. Please try again."
  end

  def almost_there
    @email = params[:email]
    return unless @email.present?

    @provider = EmailInformationService.new(@email)
    @search_url = @provider.search_url(sender: @newsletter.sending_from) if @provider.name.present?
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
  rescue JWT::ExpiredSignature, JWT::DecodeError, JWT::VerificationError, ActiveRecord::RecordNotFound
    render :invalid_confirmation
  end

  private

  def set_newsletter
    @newsletter = Newsletter.from_slug(params[:slug])
  end
end
