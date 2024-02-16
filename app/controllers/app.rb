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
        #   routing.on 'api/v1/commits' do
        #     routing.get String, String do |username, projname|
        #       github_token = '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'
        #       final_commits = []

        #       (2014..2023).each do |year|
        #         # 對每個年份構造 since 和 until 參數
        #         since = "#{year}-01-01T00:00:00Z"
        #         until_param = "#{year}-12-31T23:59:59Z"
        #         url = "https://api.github.com/repos/#{username}/#{projname}/commits?since=#{since}&until=#{until_param}&per_page=1"

        #         begin
        #           response = RestClient.get(url, { 'Authorization' => "token #{github_token}" })
        #           commits = JSON.parse(response.body)
        #           final_commits.concat(commits) unless commits.empty?
        #         rescue RestClient::ExceptionWithResponse => e
        #           puts "Failed to fetch commits for #{year}: #{e.response}"
        #         end
        #       end

        #       final_commits # 返回每年最後一筆 commit 的集合
        #     end
      end
    end
  end
end
