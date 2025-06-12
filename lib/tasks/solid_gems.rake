# RAILS MULTI-DATABASE SCHEMA BUG WORKAROUND
#
# THE PROBLEM:
# Rails has a bug with multi-database setups where running `rails db:migrate` or `rails db:prepare`
# can wipe out or fail to properly load schema files for secondary databases (queue_schema.rb, cache_schema.rb).
# This means your queue and cache databases might end up empty or missing tables after deployment.
#
# WHAT THESE TASKS DO:
# 1. Connect directly to the specific database (queue or cache)
# 2. Manually load the schema file (queue_schema.rb or cache_schema.rb)
# 3. Create the necessary tables (solid_queue_* or solid_cache_entries)
#
# WHY WE NEED THIS:
# Without these tasks, your app might boot but:
# - Background jobs fail because solid_queue tables don't exist
# - Caching fails because solid_cache_entries table doesn't exist
# - Production deployments break silently
#
# USAGE IN DEPLOYMENT:
# Run these before starting your app:
# rails solid_queue:load_schema && rails solid_cache:load_schema && puma
#
# References:
# https://github.com/rails/solid_queue/issues/329
# https://github.com/rails/rails/issues/52829
# We can remove these when Rails fixes the multi-database schema loading bug.
namespace :solid_queue do
  desc "Load SolidQueue schema into the queue database"
  task load_schema: :environment do
    config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")

    ActiveRecord::Base.establish_connection(config)

    load(Rails.root.join("db/queue_schema.rb"))

    puts "SolidQueue schema loaded successfully."
  end
end

namespace :solid_cache do
  desc "Load SolidCache schema into the cache database"
  task load_schema: :environment do
    config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "cache")

    ActiveRecord::Base.establish_connection(config)

    load(Rails.root.join("db/cache_schema.rb"))

    puts "SolidCache schema loaded successfully."
  end
end
