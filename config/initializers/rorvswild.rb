if Rails.env.production? && AppConfig.get("RORVSWILD__API_KEY").present?
  current_revision = begin
    ENV["HATCHBOX_REVISION"].presence || `git rev-parse HEAD`.strip.presence
  rescue Errno::ENOENT, StandardError
    nil
  end

  deployment_config = {}
  deployment_config[:revision] = current_revision if current_revision.present?

  RorVsWild.start(
    api_key: AppConfig.get("RORVSWILD__API_KEY"),
    deployment: deployment_config
  )
end
