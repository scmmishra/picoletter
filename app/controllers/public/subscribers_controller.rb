class Public::SubscribersController < ApplicationController
  include ActiveHashcash
  layout "application"

  before_action :set_newsletter

  before_action :check_hashcash, only: :public_subscribe unless Rails.env.test?
  skip_before_action :verify_authenticity_token, only: [ :embed_subscribe ]

  rate_limit to: 5, within: 30.minute, only: [ :embed_subscribe, :public_subscribe ]

  def embed_subscribe
    return head :forbidden if AppConfig.get("DISABLE_EMBED_SUBSCRIBE")

    # Embedded forms may fail to POST (e.g., JS disabled, iframe restrictions) and fall back to GET.
    # Redirect non-POST requests to the newsletter page so users can subscribe manually.
    unless request.post?
      redirect_to newsletter_path(@newsletter.slug), notice: "Something went wrong. You can subscribe manually from here."
      return
    end

    success_url = @newsletter.redirect_after_subscribe
    create_subscriber("embed", success_url)
  end

  def public_subscribe
    create_subscriber("public", nil)
  end

  def almost_there
    @email = params[:email]
    return unless @email.present?

    @provider = EmailInformationService.new(@email)
    @search_url = @provider.search_url(sender: @newsletter.sending_from) if @provider.name.present?
  end

  def unsubscribe
    token = params[:token]
    subscriber = Subscriber.find_by_token_for!(:unsubscribe, token)
    subscriber.unsubscribe!
    # Log the unsubscribe activity
    Rails.logger.info("Subscriber #{subscriber.id} unsubscribed from newsletter #{@newsletter.id}")
    # if request is a get, render the layout, or respond with 200 and json ok if it is a post
    if request.post?
      render json: { ok: true }
    else
      render :unsubscribed
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render :invalid_unsubscribe, status: :unprocessable_entity
  end

  def confirm_subscriber
    token = params[:token]
    subscriber = Subscriber.find_by_token_for!(:confirmation, token)

    subscriber.verify!
    redirect_url = @newsletter.redirect_after_confirm
    if redirect_url.present?
      redirect_to redirect_url, allow_other_host: true
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render :invalid_confirmation, status: :unprocessable_entity
  end

  private

  def create_subscriber(source, success_url = nil)
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
      CreateSubscriberJob.perform_now(@newsletter.id, params[:email], params[:name], params[:labels], source, analytics_data)
      if success_url.present?
        redirect_to success_url, allow_other_host: true
      else
        redirect_to almost_there_path(@newsletter.slug, email: params[:email])
      end
    else
      redirect_to newsletter_path(@newsletter.slug), notice: "Our system detected some issues with your request. Please try again."
    end
  rescue => e
    Rails.logger.error(e)
    RorVsWild.record_error(e, context: { email: params[:email], name: params[:name], source: source })
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
    head :not_found unless @newsletter
  end
end
