require 'gems'
require 'pry'
require 'figaro'
require 'rest-client'
require 'json'
require 'roda'
require 'http'

class MyApp < Roda
  plugin :json
  route do |r|
    r.on 'api/v1/commits' do
      r.get String, String do |username, projname|
        # 使用 HTTP gem 與 GitHub API 通信
        github_token = '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'
        final_commits = []

        # (2014..2023).each do |year|
          # 對每個年份構造 since 和 until 參數
          # since = "#{year}-01-01T00:00:00Z"
          # until_param = "#{year}-12-31T23:59:59Z"
          url = "https://api.github.com/repos/#{username}/#{projname}"
          # url = "https://api.github.com/repos/#{username}/#{projname}/commits?since=#{since}&until=#{until_param}&per_page=1"
          
          begin
            http_response = HTTP.headers(
            'Accept' => 'application/vnd.github.v3+json',
            'Authorization' => "token #{github_token}"
          ).get(url)
            # response = RestClient.get(url, {'Authorization' => "token #{github_token}"})
            commits = JSON.parse(http_response.body)
        
            final_commits.concat(commits) unless commits.empty?
          rescue RestClient::ExceptionWithResponse => e
            puts "Failed to fetch commits for #{year}: #{e.response}"
          end
        # end
        
        final_commits # 返回每年最後一筆 commit 的集合
      end
    end
  end
end