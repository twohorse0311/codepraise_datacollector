# frozen_string_literal: true

require 'roda'
require 'slim'
require 'slim/include'
require 'rack'

module CodePraise
  # Web App
  class App < Roda
    plugin :halt
    plugin :flash
    plugin :all_verbs # allows HTTP verbs beyond GET/POST (e.g., DELETE)
    plugin :render, engine: 'slim', views: 'app/presentation/views_html'
    plugin :public, root: 'app/presentation/public'
    plugin :assets, path: 'app/presentation/assets',
                    css: 'style.css', js: 'table_row.js'
    plugin :common_logger, $stderr

    use Rack::MethodOverride # allows HTTP verbs beyond GET/POST (e.g., DELETE)

    route do |routing|
      routing.on 'project' do
        routing.is do
          # POST /project/
          routing.post do
            gh_url = routing.params['github_url']
            unless (gh_url.include? 'github.com') &&
                   (gh_url.split('/').count == 5)
              flash[:error] = 'Invalid URL for a Github project'
              response.status = 400
              routing.redirect '/'
            end

            owner_name, project_name = gh_url.split('/')[-2..]
            project = Repository::For.klass(Entity::Project)
              .find_full_name(owner_name, project_name)

            unless project
              # Get project from Github
              begin
                project = Github::ProjectMapper
                  .new(App.config.GITHUB_TOKEN)
                  .find(owner_name, project_name)
              rescue StandardError => e
                App.logger.error e.backtrace.join("DB READ PROJ\n")
                flash[:error] = 'Could not find that Github project'
                routing.redirect '/'
              end

              # Add project to database
              begin
                Repository::For.entity(project).create(project)
              rescue StandardError
                flash[:error] = 'Project already exists'
                routing.redirect '/'
              end
            end

            # Add new project to watched set in cookies
            # session[:watching].insert(0, project.fullname).uniq!

            # Redirect viewer to project page
            routing.redirect "project/#{project.owner.username}/#{project.name}"
          end
        end

        routing.on String, String do |owner_name, project_name| # rubocop:disable Metrics/BlockLength
          # DELETE /project/{owner_name}/{project_name}
          routing.delete do
            fullname = "#{owner_name}/#{project_name}"
            session[:watching].delete(fullname)

            routing.redirect '/'
          end

          # GET /project/{owner_name}/{project_name}
          routing.get do
            path = request.remaining_path
            folder_name = path.empty? ? '' : path[1..]

            # Get project from database instead of Github
            begin
              project = Repository::For.klass(Entity::Project)
                .find_full_name(owner_name, project_name)

              if project.nil?
                flash[:error] = 'Project not found'
                routing.redirect '/'
              end
            rescue StandardError
              flash[:error] = 'Having trouble accessing the database'
              routing.redirect '/'
            end

            # Clone remote repo from project information
            begin
              gitrepo = GitRepo.new(project)
              gitrepo.clone unless gitrepo.exists_locally?
            rescue StandardError => err
              App.logger.error err.backtrace.join("GIT CLONE\n")
              flash[:error] = 'Could not clone this project'
              routing.redirect '/'
            end
            require 'pry'
            binding.pry

            commits = Repository::Commits.new(project).exist?

            unless commits
              commits = Github::CommitMapper
              .new(gitrepo.repo_local_path).get_commit_entity
              Repository::For.entity(project).update_commit(project, commits)
            end

            # Compile contributions for folder
            begin
              folder = Mapper::Contributions
                .new(gitrepo).for_folder(folder_name)
            rescue StandardError
              flash[:error] = 'Could not find that folder'
              routing.redirect "/project/#{owner_name}/#{project_name}"
            end

            if folder.empty?
              flash[:error] = 'Could not find that folder'
              routing.redirect "/project/#{owner_name}/#{project_name}"
            end

            proj_folder = Views::ProjectFolderContributions.new(project, folder)
            proj_folder
            # Show viewer the project
            # view 'project', locals: { proj_folder: }
          end
        end
      end
    end
  end
end
