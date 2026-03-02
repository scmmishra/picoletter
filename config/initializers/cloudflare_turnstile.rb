RailsCloudflareTurnstile.configure do |config|
  config.site_key = AppConfig.get("CF__TURNSTILE_SITE_KEY")
  config.secret_key = AppConfig.get("CF__TURNSTILE_SECRET")
  config.enabled = config.site_key.present? && config.secret_key.present?
  config.fail_open = false

  config.size = :flexible
  config.theme = :light
end
