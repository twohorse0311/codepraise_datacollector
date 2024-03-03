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

      def log_commits(commit_year)
        result = nil # 初始化result为nil
        Dir.chdir(@path) do
          IO.popen(full_command) do |output|
            output.each do |line|
              sha, year = line.split(' ')
              if year.to_i == commit_year
                result = { year: year.to_i, sha: sha }
                break # 满足条件，赋值给result后退出循环
              end
            end
          end
        end
        result # 返回result，如果没有找到匹配的commit_year，则为nil
      end      
    end
  end
end
