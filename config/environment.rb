# frozen_string_literal: true

require 'figaro'
require 'logger'
require 'rack/session'
require 'roda'
require 'sequel'
require 'rack/cache'
require 'redis-rack-cache'

module CodePraise
  # Environment-specific configuration
  class App < Roda
    plugin :environments

    # Environment variables setup
    Figaro.application = Figaro::Application.new(
      environment:,
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load
    def self.config = Figaro.env

    configure :development, :production do
        plugin :common_logger, $stderr
    end
    
    # Setup Cacheing mechanism
    configure :development do
      use Rack::Cache,
          verbose: true,
          metastore: 'file:_cache/rack/meta',
          entitystore: 'file:_cache/rack/body'
    end

    configure :production do
      use Rack::Cache,
          verbose: true,
          metastore: "#{config.REDIS_URL}/0/metastore",
          entitystore: "#{config.REDIS_URL}/0/entitystore"
    end

    # Automated HTTP stubbing for testing only
    configure :app_test do
      require_relative '../spec/helpers/vcr_helper'
      VcrHelper.setup_vcr
      VcrHelper.configure_vcr_for_github(recording: :none)
    end

    # Database Setup
    configure :development, :test, :app_test do
      require 'pry'; # for breakpoints
      ENV['DATABASE_URL'] = "sqlite://#{config.DB_FILENAME}"
    end

    # Database Setup
    @db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    def self.db = @db # rubocop:disable Style/TrivialAccessors

    # Logger Setup
    @logger = Logger.new($stderr)
    def self.logger = @logger # rubocop:disable Style/TrivialAccessors
  end
end