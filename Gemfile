source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Auth & Authorization
gem "devise", "~> 4.9"
gem "pundit", "~> 2.3"

# JSON:API
gem "jsonapi-serializer", "~> 2.2"

# Pagination
gem "kaminari", "~> 1.2"

# CORS
gem "rack-cors"

# Reduces boot times through caching
gem "bootsnap", require: false

gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.3"
  gem "shoulda-matchers", "~> 6.0"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "database_cleaner-active_record", "~> 2.1"
end
