# lib/tasks/queue_db.rake
namespace :db do
  namespace :prepare do
    task :queue => :environment do
      ActiveRecord::Base.establish_connection(:queue)
      config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")
      ActiveRecord::Tasks::DatabaseTasks.database_configuration = config

      # Create the database if it doesn't exist
      ActiveRecord::Tasks::DatabaseTasks.create_current

      # Check if schema_migrations table exists
      connection = ActiveRecord::Base.connection
      schema_migrations_exists = connection.data_source_exists?("schema_migrations")

      if schema_migrations_exists
        puts "Running migrations for queue database..."
        ActiveRecord::Tasks::DatabaseTasks.migrate
      else
        puts "Loading schema for queue database..."
        ActiveRecord::Tasks::DatabaseTasks.load_schema_current
      end

      # Disconnect from the queue database
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end
end
