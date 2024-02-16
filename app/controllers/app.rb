# frozen_string_literal: true

require 'roda'

module CodePraise
  # Web App
  class App < Roda
    plugin :common_logger, $stderr
    plugin :halt

    route do |routing|
      routing.on 'commits' do
        routing.is do
          # POST /commits/
          routing.post do
            gh_url = routing.params['github_url'].downcase
            routing.halt 400 unless (gh_url.include? 'github.com') &&
                                    (gh_url.split('/').count >= 3)
            owner_name, project_name = gh_url.split('/')[-2..]

            # Get project from Github
            project = Github::ProjectMapper
                      .new(App.config.GITHUB_TOKEN)
                      .find(owner_name, project_name)

            # Add project to database
            Repository::For.entity(project).create(project)

            # Redirect viewer to project page
            routing.redirect "project/#{project.owner.username}/#{project.name}"
          end
        end
      end
    end
  end
end
