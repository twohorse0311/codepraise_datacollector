# frozen_string_literal: false

require_relative 'member_mapper'

module CodePraise
  module Github
    # Data Mapper: Github repo -> Project entity
    class ProjectMapper
      def initialize(gh_token, gateway_class = Github::Api)
        @token = gh_token
        @gateway_class = gateway_class
        @gateway = @gateway_class.new(@token)
      end

      def find(owner_name, project_name)
        data = @gateway.repo_data(owner_name, project_name)
        build_entity(data, owner_name, project_name)
      end

      def build_entity(data, owner_name, project_name)
        DataMapper.new(data, @token, @gateway_class, owner_name, project_name).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data, token, gateway_class, owner_name, project_name)
          @data = data
          @member_mapper = MemberMapper.new(token, gateway_class)
          @commit_mapper = CommitMapper.new(token, gateway_class)
          @owner_name = owner_name
          @project_name = project_name
        end

        def build_entity
          CodePraise::Entity::Project.new(
            id: nil,
            origin_id: origin_id,
            name: name,
            size: size,
            ssh_url: ssh_url,
            http_url: http_url,
            owner: owner,
            contributors: contributors, 
            commits: commits
          )
        end

        def origin_id
          @data['id']
        end

        def name
          @data['name']
        end

        def size
          @data['size']
        end

        def owner
          MemberMapper.build_entity(@data['owner'])
        end

        def http_url
          @data['html_url']
        end

        def ssh_url
          @data['git_url']
        end

        def contributors
          @member_mapper.load_several(@data['contributors_url'])
        end

        def commits
          @commit_mapper.load_several(@owner_name, @project_name)
        end
      end
    end
  end
end