# frozen_string_literal: true

require_relative '../require_app'
require_app

require 'figaro'
require 'shoryuken'

module GitLog
  # Shoryuken worker class to clone repos in parallel
  class Worker
    # Environment variables setup
    Figaro.application = Figaro::Application.new(
      environment: ENV['RACK_ENV'] || 'development',
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load
    def self.config = Figaro.env

    Shoryuken.sqs_client = Aws::SQS::Client.new(
      access_key_id: config.AWS_ACCESS_KEY_ID,
      secret_access_key: config.AWS_SECRET_ACCESS_KEY,
      region: config.AWS_REGION
    )

    include Shoryuken::Worker
    Shoryuken.sqs_client_receive_message_opts = { wait_time_seconds: 20 }
    shoryuken_options queue: config.LOG_QUEUE_URL, auto_delete: true

    def perform(_sqs_msg, request)
      log_request = CodePraise::Representer::CloneRequest
        .new(OpenStruct.new)
        .from_json(request)
        
      project = log_request.project
      git_repo = CodePraise::GitRepo.new(project, Worker.config)
      commits = CodePraise::Github::CommitMapper
        .new(git_repo.repo_local_path).get_commit_entity
      CodePraise::Repository::For.klass(CodePraise::Entity::Project).update_commit(project, commits)
    rescue StandardError
      puts 'Log commits error'
    end
  end
end
