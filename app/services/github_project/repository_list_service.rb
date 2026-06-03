# frozen_string_literal: true

module GitHubProject
  class RepositoryListService
    API_BASE = "https://api.github.com"
    CACHE_TTL = 5.minutes
    PER_PAGE = 100

    class ListError < StandardError; end
    class NotConnectedError < ListError; end
    class AuthenticationError < ListError; end
    class GitHubRateLimitError < ListError; end

    def self.call(user:, include_forks: false, force_refresh: false)
      new(user: user, include_forks: include_forks, force_refresh: force_refresh).call
    end

    def initialize(user:, include_forks: false, force_refresh: false)
      @user = user
      @include_forks = include_forks
      @force_refresh = force_refresh
    end

    def call
      raise NotConnectedError, "Connect GitHub to browse your repositories." unless user.github_oauth_connected?

      cache_key = "github_project:repo_list:#{user.id}:#{include_forks ? 1 : 0}"
      if force_refresh
        fetch_repositories
      else
        Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { fetch_repositories }
      end
    end

    private

    attr_reader :user, :include_forks, :force_refresh

    def fetch_repositories
      raw_repos = get(
        "/user/repos",
        affiliation: "owner",
        sort: "pushed",
        direction: "desc",
        per_page: PER_PAGE
      )
      repos = Array(raw_repos).map { |repo| normalize_repo(repo) }
      repos = repos.reject { |repo| repo["fork"] } unless include_forks
      repos.sort_by { |repo| [ repo["archived"] ? 1 : 0, -pushed_at_sort_key(repo["pushed_at"]) ] }
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed
      raise ListError, "Could not reach GitHub. Please try again."
    end

    def pushed_at_sort_key(value)
      return 0 if value.blank?

      Time.zone.parse(value.to_s).to_i
    rescue ArgumentError, TypeError
      0
    end

    def normalize_repo(repo)
      {
        "full_name" => repo["full_name"],
        "url" => repo["html_url"],
        "description" => repo["description"].to_s.presence,
        "private" => repo["private"] == true,
        "fork" => repo["fork"] == true,
        "archived" => repo["archived"] == true,
        "language" => repo["language"].to_s.presence,
        "pushed_at" => repo["pushed_at"]
      }
    end

    def get(path, params = {})
      uri = URI(API_BASE + path)
      uri.query = URI.encode_www_form(params) if params.present?

      response = connection.get(uri.request_uri, nil, headers)
      return response.body if response.success?

      case response.status
      when 401
        raise AuthenticationError, "GitHub connection expired. Reconnect GitHub and try again."
      when 403
        raise GitHubRateLimitError, "GitHub API rate limit reached. Try again in a few minutes."
      else
        raise ListError, "Could not load repositories from GitHub."
      end
    end

    def connection
      @connection ||= Faraday.new(url: API_BASE) do |f|
        f.request :json
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end

    def headers
      {
        "Accept" => "application/vnd.github+json",
        "X-GitHub-Api-Version" => "2022-11-28",
        "Authorization" => "Bearer #{user.github_oauth_token_for_insights}"
      }
    end
  end
end
