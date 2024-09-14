Pico::Billing.setup do |config|
  config.user_class_name = "User"
  config.lemon_squeezy_api_key = AppConfig.get("LEMON_SQUEEZY__API_KEY", nil)
  config.store_id = AppConfig.get("LEMON_SQUEEZY__STORE_ID", nil)
  config.product_id = AppConfig.get("LEMON_SQUEEZY__PRODUCT_ID", nil)
  config.product_name = AppConfig.get("LEMON_SQUEEZY__PRODUCT_NAME", "Picoletter")
  config.product_variant_id = AppConfig.get("LEMON_SQUEEZY__PRODUCT_VARIANT_ID", nil)
end

# Pico::Billing.initialize_lemon_squeezy
