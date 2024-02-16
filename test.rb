require 'rest-client'
require 'json'
require 'pry'

# frozen_string_literal: true

require 'http'

class Api
  def initialize(token)
    @github_token = token
  end

  def repo_data(username, project_name)
    Request.new(@github_token).repo(username, project_name).parse
  end

  def contributors_data(contributors_url)
    Request.new(@github_token).get(contributors_url).parse
  end

  def commit_data(username, project_name)
    Request.new(@github_token).commit(username, project_name).parse
  end

  # Sends out HTTP requests to Github
  class Request
    REPOS_PATH = 'https://api.github.com/repos/'

    def initialize(token)
      @token = token
    end

    def repo(username, project_name)
      get(REPOS_PATH + [username, project_name].join('/'))
    end

    def commit(username, project_name)
      final_commits = []
      (2014..2023).each do |year|
        # 對每個年份構造 since 和 until 參數
        since = "#{year}-01-01T00:00:00Z"
        until_param = "#{year}-12-31T23:59:59Z"
        response = get(REPOS_PATH + "#{username}/#{project_name}/commits?since=#{since}&until=#{until_param}&per_page=1")
        final_commits.concat(response) unless commits.empty?
      end
    end

    def get(url)
      http_response = HTTP.headers(
        'Accept' => 'application/vnd.github.v3+json',
        'Authorization' => "token #{@token}"
      ).get(url)

      Response.new(http_response).tap do |response|
        raise(response.error) unless response.successful?
      end
    end
  end

  # Decorates HTTP responses from Github with success/error
  class Response < SimpleDelegator
    Unauthorized = Class.new(StandardError)
    NotFound = Class.new(StandardError)

    HTTP_ERROR = {
      401 => Unauthorized,
      404 => NotFound
    }.freeze

    def successful?
      HTTP_ERROR.keys.none?(code)
    end

    def error
      HTTP_ERROR[code]
    end
  end
end

username = 'rubygems'
project_name = 'rubygems'

a = Api.new('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').commit_data(username, project_name)

# 設定 API 的 URL

# url = "http://localhost:9090/api/v1/commits/#{username}/#{projname}" # 確保端口與您的 Roda 應用一致

# begin
#   # 發送 GET 請求
#   response = RestClient.get(url)

#   # 解析 JSON 回應
#   commits = JSON.parse(response.body)

#   # 在這裡處理您的回傳數據，例如打印出來
#   puts "Commits: #{commits}"
# #   binding.pry
# rescue RestClient::ExceptionWithResponse => e
#   puts "An error occurred: #{e.response}"
# end
