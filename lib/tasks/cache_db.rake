# lib/tasks/cache_db.rake
namespace :db do
  namespace :prepare do
    task cache: :environment do
      ActiveRecord::Base.establish_connection(:cache)
      config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "cache")
      ActiveRecord::Tasks::DatabaseTasks.database_configuration = config

      # Create the database if it doesn't exist
      ActiveRecord::Tasks::DatabaseTasks.create_current

      # Check if schema_migrations table exists
      connection = ActiveRecord::Base.connection
      schema_migrations_exists = connection.data_source_exists?("schema_migrations")

      if schema_migrations_exists
        puts "Running migrations for cache database..."
        ActiveRecord::Tasks::DatabaseTasks.migrate
      else
        puts "Loading schema for cache database..."
        ActiveRecord::Tasks::DatabaseTasks.load_schema_current
      end

      # Disconnect from the cache database
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end
end
