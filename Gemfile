# frozen_string_literal: true

source 'https://rubygems.org'
ruby File.read('.ruby-version').strip
# CONFIGURATION
gem 'figaro', '~> 1.2'
gem 'pry'
gem 'rake', '~> 13.0'

# PRESENTATION LAYER

gem 'slim', '~> 5.0'

# APPLICATION LAYER
# Web application related
gem 'puma', '~> 6.0'
gem 'rack-session', '~> 0.3'
gem 'roda', '~> 3.0'

# Controllers and services
gem 'dry-monads', '~> 1.4'
gem 'dry-transaction', '~> 0.13'
gem 'dry-validation', '~> 1.7'

# DOMAIN LAYER
# Validation
gem 'dry-struct', '~> 1.0'
gem 'dry-types', '~> 1.0'

# INFRASTRUCTURE LAYER
# Networking
gem 'http', '~> 5.0'

# Database
gem 'hirb'
# gem 'hirb-unicode' # incompatible with new rubocop
gem 'sequel', '~> 5.0'

group :development, :test do
  gem 'sqlite3', '~> 1.0'
end

group :production do
  gem 'pg', '~> 1.2'
end

# TESTING
group :test do
  gem 'minitest', '~> 5.0'
  gem 'minitest-rg', '~> 5.0'
  gem 'simplecov', '~> 0.0'
  gem 'vcr', '~> 6.0'
  gem 'webmock', '~> 3.0'

  gem 'headless', '~> 2.3'
  gem 'page-object', '~> 2.3'
  gem 'watir', '~> 7.0'
  # gem 'webdrivers', '~> 5.0'
  gem 'selenium-webdriver', '~> 4.11'
end

# Development
group :development do
  gem 'flog'
  gem 'reek'
  gem 'rerun', '~> 0.0'
  gem 'rubocop', '~> 1.0'
end