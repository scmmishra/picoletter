# get rails encrypted credentials
ActiveSupport.on_load(:action_mailer) do
  Resend.api_key = AppConfig.get("RESEND__API_KEY")
end
