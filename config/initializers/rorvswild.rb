if Rails.env.production? && AppConfig.get("RORVSWILD__API_KEY").present?
  RorVsWild.start(api_key: AppConfig.get("RORVSWILD__API_KEY"))
end
