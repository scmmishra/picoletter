source "https://rubygems.org"

ruby "3.4.4"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"

# Use pg as the database for Active Record
gem "pg", "~> 1.5"

# Use PostgreSQL array for labels
gem "acts-as-taggable-array-on"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# SolidQueue
gem "solid_queue", "~> 1.2.3"
gem "mission_control-jobs", "~> 1.1.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire"s SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire"s modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# OmniAuth for social login
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-github", "~> 2.0.0"
gem "omniauth-google-oauth2"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"
gem "aws-sdk-s3", require: false
gem "resolv"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails", "~> 6.1.0"
  gem "byebug", "~> 11.1"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "simplecov"
  gem "skooma"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem "rubocop-rails-omakase", require: false
  gem "annotaterb"
  gem "letter_opener"
  gem "erb-formatter"
  gem "hotwire-spark"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

gem "tailwindcss-rails", "~> 3.3.1"
gem "pagy"

# HTML parsing
gem "nokogiri"

# Markdown
gem "kramdown"

# For handling email styles
gem "premailer-rails"

# monitoring
gem "rorvswild", ">= 1.10.0"

# production
gem "dotenv-rails"

gem "lucide-rails", "~> 0.7.1"
gem "logtail-rails", "~> 0.2.7"
gem "solid_cache", "~> 1.0.8"

gem "httparty"

# this will detect bots
gem "browser"
gem "valid_email2"
gem "cloudflare-rails"

# to parse maxmind db
gem "aws-sdk-rails", "~> 3"

# Bot prevention
gem "active_hashcash", github: "BaseSecrete/active_hashcash"
gem "liquid"

gem "reactionview", "~> 0.1.6"
