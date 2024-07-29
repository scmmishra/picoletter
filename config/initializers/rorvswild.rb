if Rails.env.production?
  RorVsWild.start(api_key: AppConfig.get("RORVSWILD__API_KEY"))
end
