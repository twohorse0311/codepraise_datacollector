# frozen_string_literal: true

require 'base64'

require_relative 'command'

module CodePraise
  module Git
    # USAGE:
    #   load 'infrastructure/gitrepo/gitrepo.rb'
    #   origin = Git::RemoteGitRepo.new('git@github.com:soumyaray/YPBT-app.git')
    #   local = Git::LocalGitRepo.new(origin, 'infrastructure/gitrepo/repostore')

    # Manage remote Git repository for cloning
    class LogReporter
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def full_command
        Git::Command.new
          .log
          .with_formatcommit
          .with_formatdate
          .full_command
      end

      def log_commits
        commits_by_year = {}

        Dir.chdir(@path) do
          IO.popen(full_command) do |output|
            output.each do |line|
              sha, year = line.split(' ')
              next unless year.to_i.between?(2014, 2023)

              unless commits_by_year.key?(year.to_i)
                commits_by_year[year.to_i] = { year: year.to_i, sha: }
              end
            end
          end
        end
        commits_by_year.values
      end
    end
  end
end
