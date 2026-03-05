source "https://rubygems.org"

ruby "3.4.4"

# Framework and app server
gem "rails", "~> 8.1.1"
gem "lexxy", github: "basecamp/lexxy"
gem "puma", ">= 5.0"

# Database
gem "pg", "~> 1.5"
gem "acts-as-taggable-array-on"

# Asset pipeline and frontend
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 3.3.1"

# Background jobs and caching
gem "thruster", require: false
gem "solid_queue", "~> 1.2.3"
gem "mission_control-jobs", "~> 1.1.0"
gem "solid_cache", "~> 1.0.8"

# Authentication
gem "bcrypt", "~> 3.1.7"
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-github", "~> 2.0.0"
gem "omniauth-google-oauth2"

# Content and rendering
gem "pagy"
gem "nokogiri"
gem "rouge"
gem "kramdown"
gem "premailer-rails"
gem "liquid"
gem "lucide-rails", "~> 0.7.1"
gem "reactionview"

# Integrations and utilities
gem "aws-sdk-rails", "~> 3"
gem "aws-sdk-s3", require: false
gem "httparty"
gem "browser"
gem "valid_email2"
gem "cloudflare-rails"
gem "resolv"

# Bot protection
gem "active_hashcash", github: "BaseSecrete/active_hashcash"
gem "rails_cloudflare_turnstile"

# Active Storage variants
gem "image_processing", "~> 1.2"

# Platform and boot performance
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false

# Optional JSON APIs
# gem "jbuilder"

# Optional Redis-backed features
# gem "redis", ">= 4.0.1"
# gem "kredis"

group :development, :test do
  # Debugger and test helpers
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails", "~> 6.1.0"
  gem "byebug", "~> 11.1"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "simplecov"
  gem "skooma"
  gem "dotenv-rails"
end

group :development do
  # Developer tooling
  gem "web-console"
  gem "rubocop-rails-omakase", require: false
  gem "annotaterb"
  gem "letter_opener"
  gem "erb-formatter"
  gem "hotwire-spark"
end

group :development, :production do
  # Monitoring
  gem "rorvswild", ">= 1.11.0"
end

group :production do
  # Log shipping
  gem "logtail-rails", "~> 0.2.7"
end
