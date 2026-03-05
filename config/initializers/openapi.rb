openapi_path = Rails.root.join("docs/openapi.yml")

Rails.application.config.x.openapi_spec = if File.exist?(openapi_path)
  YAML.safe_load_file(openapi_path, aliases: true) || {}
else
  {}
end
