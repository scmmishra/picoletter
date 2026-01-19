RailsCloudflareTurnstile.configure do |c|
  site_key = ENV["CF_TURNSTILE_SITE_KEY"]
  secret_key = ENV["CF_TURNSTILE_SECRET"]

  # Enable Turnstile only if both keys are present
  c.enabled = site_key.present? && secret_key.present?

  if c.enabled
    c.site_key = site_key
    c.size = :flexible
    c.theme = :light
    c.secret_key = secret_key
    c.fail_open = true
  end

  # Enable mock in development/test if real credentials are not present
  c.mock_enabled = !c.enabled && (Rails.env.development? || Rails.env.test?)
end
