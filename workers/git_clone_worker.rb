# frozen_string_literal: true

require_relative '../require_app'
require_relative 'clone_monitor'
require_relative 'appraise_service'
require_relative 'job_reporter'
require_app

require 'figaro'
require 'shoryuken'

module GitClone
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
    shoryuken_options queue: config.CLONE_QUEUE_URL, auto_delete: true

    def perform(_sqs_msg, request)
      project, reporter, request_id = setup_job(request)
      gitrepo = CodePraise::GitRepo.new(project, Worker.config)
      service = Service.new(project, reporter, gitrepo, request_id)
      service.clone_project

      commit_mapper = CodePraise::Github::CommitMapper.new(gitrepo)
      commits = 2023.downto(2014).map do |commit_year|
        next nil if service.store_commits(commit_year).nil?
        service.appraise_project
        service.store_appraisal_cache
        commit_mapper.get_commit_entity(commit_year)
      end.compact
      CodePraise::Repository::For.klass(CodePraise::Entity::Project).update_commit(project, commits)
      # Keep sending finished status to any latecoming subscribers
      each_second(15) do
        reporter.publish(CloneMonitor.finished_percent, 'stored', request_id)
      end
    rescue CodePraise::GitRepo::Errors::CannotOverwriteLocalGitRepo
      # worker should crash fail early - only catch errors we expect!
      puts 'CLONE EXISTS -- ignoring request'
    end

    private

    def setup_job(request)
      clone_request = CodePraise::Representer::CloneRequest
        .new(OpenStruct.new).from_json(request)

      [clone_request.project,
       ProgressReporter.new(Worker.config, clone_request.id),
       clone_request.id]
    end

    def each_second(seconds)
      seconds.times do
        sleep(1)
        yield if block_given?
      end
    end
  end
end
