# frozen_string_literal: true

source 'https://rubygems.org'

# Configuration and Utilities
gem 'figaro', '~> 1.0'
gem 'pry'
gem 'rake'

# Web Application
gem 'puma', '~> 6.0'
gem 'roda', '~> 3.0'
gem 'slim', '~> 5.0'

# Data Validation
gem 'dry-struct', '~> 1.0'
gem 'dry-types', '~> 1.0'

# Networking
gem 'http', '~> 5.0'

# Database
gem 'hirb'
# gem 'hirb-unicode' # incompatible with new rubocop
gem 'sequel', '~> 5.0'

group :development, :test do
  gem 'sqlite3', '~> 1.0'
end

# Testing
group :test do
  gem 'minitest', '~> 5.0'
  gem 'minitest-rg', '~> 5.0'
  gem 'simplecov', '~> 0.0'
  gem 'vcr', '~> 6.0'
  gem 'webmock', '~> 3.0'
end

# Development
group :development do
  gem 'flog'
  gem 'reek'
  gem 'rerun', '~> 0.0'
  gem 'rubocop', '~> 1.0'
end