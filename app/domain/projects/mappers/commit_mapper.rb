# frozen_string_literal: false

module CodePraise
  # Provides access to project commit
  module Github
    class CommitMapper
      def initialize(path)
        @path = path
      end

      def get_commit_entity
        commits_by_year = {}
      
        full_command = Git::Command.new
          .log
          .with_formatcommit
          .with_formatdate
          .full_command
      
        Dir.chdir(@path) do
          IO.popen(full_command) do |output|
            output.each do |line|
              sha, year = line.split(' ')
              next unless year.to_i.between?(2014, 2023)
              unless commits_by_year.key?(year.to_i)
                commits_by_year[year.to_i] = { year: year.to_i, sha: sha }
              end
            end
          end
        end
        commits_by_year.values
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
            sha:,
            commit_date:
          )
        end

        private

        def sha
          @commit[:sha]
        end

        def commit_date
          @commit[:year]
        end
      end
    end
  end
end
