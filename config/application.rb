require_relative "boot"

require "rails/all"

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
    config.host = ENV.fetch("PICO_HOST", "http://localhost:3000")
    config.support_email = ENV.fetch("PICO_SUPPORT_EMAIL", "support@picoletter.com")
    if AppConfig.get('BETTERSTACK__LOGS_TOKEN'):
      config.logger = Logtail::Logger.create_default_logger(AppConfig.get('BETTERSTACK__LOGS_TOKEN'))
    end

    # default host for emails and rendering
    config.action_mailer.default_url_options = { host: config.host }
    config.action_controller.default_url_options = { host: config.host }

    # create Isolated connection pools for reader and writer
    # ref: https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter?tab=readme-ov-file#isolated-connection-pools
    #
    # NOTE: THIS IS DISABLED FOR NOW
    # Error: EnhancedSQLite3::Error: development has 2 configurations (EnhancedSQLite3::Error)
    # See: https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter/issues/22
    # config.enhanced_sqlite3.isolate_connection_pools = true
  end
end
