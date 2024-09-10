# this is because the schema is not loaded and overriden by rails on migrate
# https://github.com/rails/solid_queue/issues/329
# We can remove it when this is fixed https://github.com/rails/rails/issues/52829
namespace :solid_queue do
  desc "Load SolidQueue schema into the queue database"
  task load_schema: :environment do
    config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")

    ActiveRecord::Base.establish_connection(config)

    load(Rails.root.join("db/queue_schema.rb"))

    puts "SolidQueue schema loaded successfully."
  end
end
