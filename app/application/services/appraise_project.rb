# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Analyzes contributions to a project
    class AppraiseProject
      include Dry::Transaction

      step :retrieve_remote_project
      step :clone_remote
      step :store_commit
      step :appraise_contributions

      private

      NO_PROJ_ERR = 'Project not found'
      DB_ERR = 'Having trouble accessing the database'
      CLONE_ERR = 'Could not clone this project'
      GET_COMMIT_ERR = 'Could not get the commits of this project'
      NO_FOLDER_ERR = 'Could not find that folder'

      def retrieve_remote_project(input)
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

      def clone_remote(input)
        gitrepo = GitRepo.new(input[:project])
        gitrepo.clone unless gitrepo.exists_locally?

        Success(input.merge(gitrepo:))
      rescue StandardError
        # App.logger.error error.backtrace.join("\n")
        Failure(Response::ApiResult.new(status: :internal_error, message: CLONE_ERR))
      end

      def store_commit(input)
        commits_from_log(input) unless commits_stored(input[:project])
        input[:project] = Repository::For.klass(Entity::Project).find_full_name(
          input[:requested].owner_name, input[:requested].project_name
        )
        Success(input)
      rescue StandardError
        Failure(Response::ApiResult.new(status: :internal_error, message: GET_COMMIT_ERR))
      end

      def appraise_contributions(input)
        input[:folder] = Mapper::Contributions
          .new(input[:gitrepo]).for_folder(input[:requested].folder_name)
        p input[:project]
        appraisal = Response::ProjectFolderContributions.new(input[:project], input[:folder])
        Success(Response::ApiResult.new(status: :ok, message: appraisal))
      rescue StandardError
        App.logger.error "Could not find: #{full_request_path(input)}"
        Failure(Response::ApiResult.new(status: :not_found, message: NO_FOLDER_ERR))
      end

      # Helper methods

      def full_request_path(input)
        [input[:requested].owner_name,
         input[:requested].project_name,
         input[:requested].folder_name].join('/')
      end

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
    end
  end
end
