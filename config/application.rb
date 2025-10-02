require_relative "boot"

require "rails/all"
require "uri"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PicoLetter
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # jobs
    config.mission_control.jobs.base_controller_class = "AdminController"
    config.mission_control.jobs.http_basic_auth_enabled = false

    # Use a different cache store in production.
    config.cache_store = :solid_cache_store

    # Use a real queuing backend for Active Job (and separate queues per environment).
    config.mission_control.jobs.adapters = [ :solid_queue ]
    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = { database: { writing: :queue } }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # pico config
    # TODO: this is not a good pattern, we need to shift to using AppConfig outside this
    config.host = ENV.fetch("PICO_HOST", "http://localhost:3000")

    primary_uri = URI(config.host)
    config.hosts = [primary_uri.host]
    config.hosts << "#{primary_uri.host}:#{primary_uri.port}" if primary_uri.port

    if (publishing_domain = AppConfig.get("PLATFORM_PUBLISHING_DOMAIN", nil))
      config.hosts << "*.#{publishing_domain}"
    end

    config.support_email = ENV.fetch("PICO_SUPPORT_EMAIL", "support@picoletter.com")
    if ENV.fetch("BETTERSTACK__LOGS_TOKEN", nil)
      config.logger = Logtail::Logger.create_default_logger(ENV.fetch("BETTERSTACK__LOGS_TOKEN", nil))
    end

    # default host for emails and rendering
    config.action_mailer.default_url_options = { host: config.host }
    config.action_controller.default_url_options = { host: config.host }

    # Setup ActiveStorage to accept webp images
    Rails.application.config.active_storage.web_image_content_types = %w[image/png image/jpeg image/gif image/webp]

    # Enable YJIT
    Rails.application.config.yjit = true
  end
end
