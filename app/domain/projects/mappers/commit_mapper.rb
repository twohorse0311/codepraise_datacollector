# frozen_string_literal: false

module CodePraise
  # Provides access to project commit
  module Github
    class CommitMapper
      def initialize(gh_token, gateway_class = Github::Api)
        @token = gh_token
        @gateway_class = gateway_class
        @gateway = @gateway_class.new(@token)
      end

      def load_several(owner_name, project_name)
        @gateway.commit_data(owner_name, project_name).map do |commit|
          CommitMapper.build_entity(commit)
        end
      end

      def self.build_entity(commit)
        DataMapper.new(commit).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(commit)
          @commit = commit
        end

        def build_entity
          Entity::Commit.new(
            id: nil,
            origin_id: origin_id,
            sha: sha,
            commit_date: commit_date
          )
        end

        private

        def origin_id
          @commit['node_id']
        end

        def sha
          @commit['sha']
        end

        def commit_date
          @commit['commit']['committer']['date']
        end
      end
    end
  end
end
