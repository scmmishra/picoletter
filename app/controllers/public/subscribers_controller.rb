class Public::SubscribersController < ApplicationController
  layout "application"

  before_action :set_newsletter
  skip_before_action :verify_authenticity_token, only: [ :embed_subscribe ]

  throttle to: 5, within: 30.minute, only: [ :embed_subscribe, :public_subscribe ], block_bots: true

  def embed_subscribe
    return head :forbidden if AppConfig.get("DISABLE_EMBED_SUBSCRIBE")
    create_subscriber("embed")
  end

  def public_subscribe
    create_subscriber("public")
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

  def create_subscriber(source)
    browser = Browser.new(request.user_agent)

    analytics_data = {
      browser: browser.name,
      browser_version: browser.version,
      platform: browser.platform.name,
      platform_version: browser.platform.version,
      device_type: detect_device_type(browser),
      referrer_url: request.referer,
      language: browser.accept_language.first&.code,
      country_code: nil,
      utm_source: params[:utm_source],
      utm_medium: params[:utm_medium],
      utm_campaign: params[:utm_campaign],
      utm_term: params[:utm_term],
      utm_content: params[:utm_content]
    }

    # if request has a cloudflare `CF-IPCountry` header, add it to the analytics data
    analytics_data[:country_code] = request.headers["CF-IPCountry"] if request.headers["CF-IPCountry"].present?

    legit_ip = IPShieldService.legit_ip?(request.remote_ip)

    if legit_ip
      CreateSubscriberJob.perform_later(@newsletter.id, params[:email], params[:name], source, analytics_data)
      redirect_to almost_there_path(@newsletter.slug, email: params[:email])
    else
      redirect_to newsletter_path(@newsletter.slug), notice: "Our system detected some issues with your request. Please try again."
    end
  rescue => e
    Rails.logger.error(e)
    RorVsWild.record_error(exception, context: { email: params[:email], name: params[:name], source: source })
    redirect_to newsletter_path(@newsletter.slug), notice: "Seems like you entered an invalid email. Please try again."
  end

  def detect_device_type(browser)
    if browser.device.mobile?
      "mobile"
    elsif browser.device.tablet?
      "tablet"
    elsif browser.device.tv?
      "tv"
    elsif browser.device.console?
      "console"
    else
      "desktop"
    end
  end

  def set_newsletter
    @newsletter = Newsletter.from_slug(params[:slug])
  end
end
