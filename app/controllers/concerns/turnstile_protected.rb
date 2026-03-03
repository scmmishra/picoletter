module TurnstileProtected
  extend ActiveSupport::Concern

  included do
    helper_method :turnstile_enabled?
  end

  class_methods do
    def protect_with_turnstile(**options)
      before_action :check_turnstile, **options, if: :turnstile_enabled?
    end
  end

  private

  def check_turnstile
    validate_cloudflare_turnstile
  rescue RailsCloudflareTurnstile::Forbidden
    redirect_to turnstile_failure_redirect_path, notice: turnstile_failure_message
  end

  def turnstile_enabled?
    turnstile_site_key.present? && turnstile_secret_key.present?
  end

  def turnstile_site_key
    AppConfig.get("CF__TURNSTILE_SITE_KEY")
  end

  def turnstile_secret_key
    AppConfig.get("CF__TURNSTILE_SECRET")
  end

  def turnstile_failure_redirect_path
    request.referer.presence || "/"
  end

  def turnstile_failure_message
    "Please complete the security check and try again."
  end
end
