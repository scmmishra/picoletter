Pico::Billing.setup do |config|
  config.user_class_name = "User"
  config.lemon_squeezy_api_key = AppConfig.get("LEMON_SQUEEZY_API_KEY", nil)
end

# Pico::Billing.initialize_lemon_squeezy
