# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Analyzes contributions to a project
    class AppraiseProject
      include Dry::Transaction

      step :find_project_details
      step :check_sha
      step :check_project_eligibility
      step :request_cloning_worker
      # step :request_logging_worker
      step :appraise_contributions

      private

      NO_PROJ_ERR = 'Project not found'
      DB_ERR = 'Having trouble accessing the database'
      CLONE_ERR = 'Could not clone this project'
      GET_COMMIT_ERR = 'Could not get the commits of this project'
      NO_FOLDER_ERR = 'Could not find that folder'
      SIZE_ERR = 'Project too large to analyze'
      PROCESSING_MSG = 'Appraising the project'
      SHA_ERR = 'Invalid sha code'
      LOGGING_MSG = 'Logging commits from project'

      # input hash keys expected: :project, :requested, :config
      def find_project_details(input)
        input[:project] = Repository::For.klass(Entity::Project).find_full_name(
          input[:requested].owner_name, input[:requested].project_name
        )

        if input[:project]
          Success(input)
        else
          Failure(Response::ApiResult.new(status: :not_found, message: NO_PROJ_ERR))
        end
      rescue StandardError
        Failure(Response::ApiResult.new(status: :internal_error, message: DB_ERR))
      end

      def check_sha(input)
        commits_list = Repository::For.klass(Entity::Project).commit_lists(
          input[:requested].owner_name, input[:requested].project_name
        ).unshift("")

        if commits_list.include?(input[:requested].commit)
          input[:sha] = input[:requested].commit != "" ? input[:requested].sha : commits_list.last
          Success(input)
        else
          Failure(Response::ApiResult.new(status: :bad_request, message: SHA_ERR))
        end
      end

      def check_project_eligibility(input)
        if input[:project].too_large?
          Failure(Response::ApiResult.new(status: :bad_request, message: SIZE_ERR))
        else
          input[:gitrepo] = GitRepo.new(input[:project], input[:config])
          Success(input)
        end
      end

      

      def request_cloning_worker(input)
        return Success(input) if input[:gitrepo].exists_locally?

        Messaging::Queue.new(App.config.CLONE_QUEUE_URL, App.config).send(clone_request_json(input))

        Failure(Response::ApiResult.new(
                  status: :processing,
                  message: { request_id: input[:request_id], msg: PROCESSING_MSG }
                ))
      rescue StandardError => e
        log_error(e)
        Failure(Response::ApiResult.new(status: :internal_error, message: CLONE_ERR))
      end

      def appraise_contributions(input)
        input[:folder] = Mapper::Contributions
          .new(input[:gitrepo]).for_folder("")
        appraisal = Response::ProjectFolderContributions.new(input[:project], input[:folder])
        Success(Response::ApiResult.new(status: :ok, message: appraisal))
      rescue StandardError
        Failure(Response::ApiResult.new(status: :not_found, message: NO_FOLDER_ERR))
      end

      # Helper methods

      def commits_from_log(input)
        commits = Github::CommitMapper
          .new(input[:gitrepo].repo_local_path).get_commit_entity
        Repository::For.entity(input[:project]).update_commit(input[:project], commits)
      rescue StandardError
        raise 'Could not get commits history from git log'
      end

      def commits_stored(project)
        Repository::Commits.new(project).exist?
      end

      def log_error(error)
        App.logger.error [error.inspect, error.backtrace].flatten.join("\n")
      end

      def clone_request_json(input)
        Response::CloneRequest.new(input[:project], input[:request_id])
          .then { Representer::CloneRequest.new(_1) }
          .then(&:to_json)
      end

      def log_request_json(input)
        Response::CloneRequest.new(input[:project], input[:request_id])
          .then { Representer::CloneRequest.new(_1) }
          .then(&:to_json)
      end
    end
  end
end
