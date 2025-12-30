source "https://rubygems.org"

gem "rails", "~> 8.0.2"
gem "pg", "~> 1.6"
gem "puma", "~> 6.6"
gem "faraday", "~> 2.7"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

gem "mail", "~> 2.8"
# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"
gem "jwt"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache and Active Job
# gem "solid_cache"
# gem "solid_queue"

# Reduces boot times through caching; required in config/boot.rb
# gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
# gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
# gem "thruster", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

group :development, :test do
  gem "dotenv-rails", "~> 3.1.8"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "pry-rails"

  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker" # (Optional: for generating test data)
  gem "shoulda-matchers", "~> 6.0"
  gem "simplecov", require: false
  # gem "parallel_tests"
end
