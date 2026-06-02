# frozen_string_literal: true

module GitHubInsights
  class FetchService
    API_BASE = "https://api.github.com"
    FILE_TREE_LIMIT_LIGHT = 120
    FILE_TREE_LIMIT_DEEP = 200
    COMMIT_LIMIT_LIGHT = 100
    COMMIT_LIMIT_DEEP = 500
    PULL_REQUEST_LIMIT_DEEP = 200
    ISSUE_LIMIT_DEEP = 200
    CONTRIBUTOR_LIMIT_DEEP = 100
    CONTENT_MAX_BYTES = 60_000
    MANIFEST_PATHS = [
      "Gemfile",
      "Gemfile.lock",
      "package.json",
      "yarn.lock",
      "pnpm-lock.yaml",
      "requirements.txt",
      "pyproject.toml",
      "go.mod",
      "Dockerfile",
      ".github/workflows"
    ].freeze
    VALID_SYNC_TYPES = %w[light deep].freeze

    class FetchError < StandardError; end
    class TemporaryFetchError < FetchError; end
    class RepositoryNotFoundError < FetchError; end
    class AuthenticationError < FetchError; end
    class GitHubRateLimitError < TemporaryFetchError; end

    def self.call(owner:, repo:, sync_type: "light", oauth_token: nil)
      new(oauth_token: oauth_token).call(owner:, repo:, sync_type:)
    end

    def initialize(oauth_token: nil)
      @oauth_token = oauth_token.to_s.presence
    end

    def call(owner:, repo:, sync_type: "light")
      sync_mode = sync_type.to_s
      raise FetchError, "Unsupported sync_type: #{sync_type}" unless VALID_SYNC_TYPES.include?(sync_mode)

      coords = { owner: owner.to_s, repo: repo.to_s }
      metadata = fetch_repo(coords)
      default_branch = metadata["default_branch"].presence || "main"

      payload = {
        "repo" => metadata,
        "languages" => fetch_languages(coords),
        "readme" => fetch_readme(coords),
        "tree_paths" => fetch_tree_paths(coords, default_branch, deep: sync_mode == "deep"),
        "manifests" => fetch_manifests(coords, default_branch),
        "fetched_at" => Time.current.iso8601,
        "sync_type" => sync_mode
      }

      commits_limit = sync_mode == "deep" ? COMMIT_LIMIT_DEEP : COMMIT_LIMIT_LIGHT
      payload["commits"] = fetch_commits(coords, per_page: commits_limit)

      if sync_mode == "deep"
        payload["pull_requests"] = fetch_pull_requests(coords, per_page: PULL_REQUEST_LIMIT_DEEP)
        payload["issues"] = fetch_issues(coords, per_page: ISSUE_LIMIT_DEEP)
        payload["contributors"] = fetch_contributors(coords, per_page: CONTRIBUTOR_LIMIT_DEEP)
        payload["releases"] = fetch_releases(coords)
      end

      payload
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise TemporaryFetchError, "GitHub request failed: #{e.message}"
    rescue Faraday::Error => e
      raise FetchError, "GitHub request failed: #{e.message}"
    end

    private

    def fetch_repo(coords)
      get("/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}")
    end

    def fetch_languages(coords)
      response = get("/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/languages")
      return [] unless response.is_a?(Hash)

      total = response.values.sum.to_f
      response.map do |language, bytes|
        {
          "name" => language,
          "bytes" => bytes,
          "share" => total.positive? ? ((bytes / total) * 100).round(2) : 0
        }
      end.sort_by { |entry| -entry["bytes"] }
    end

    def fetch_commits(coords, per_page:)
      response = get("/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/commits", per_page: per_page)
      response.is_a?(Array) ? response : []
    end

    def fetch_pull_requests(coords, per_page:)
      response = get(
        "/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/pulls",
        state: "all",
        sort: "updated",
        direction: "desc",
        per_page: per_page
      )
      response.is_a?(Array) ? response : []
    end

    def fetch_issues(coords, per_page:)
      response = get(
        "/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/issues",
        state: "all",
        sort: "updated",
        direction: "desc",
        per_page: per_page
      )
      return [] unless response.is_a?(Array)

      response.reject { |issue| issue["pull_request"].present? }
    end

    def fetch_contributors(coords, per_page:)
      response = get("/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/contributors", per_page: per_page)
      response.is_a?(Array) ? response : []
    end

    def fetch_releases(coords)
      response = get(
        "/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/releases",
        allow_not_found: true,
        per_page: 50
      )
      response.is_a?(Array) ? response : []
    end

    def fetch_tree_paths(coords, branch, deep:)
      response = get(
        "/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/git/trees/#{escaped(branch)}",
        recursive: 1
      )
      return [] unless response.is_a?(Hash)

      limit = deep ? FILE_TREE_LIMIT_DEEP : FILE_TREE_LIMIT_LIGHT
      Array(response["tree"])
        .select { |node| node["type"] == "blob" }
        .map { |node| node["path"].to_s }
        .first(limit)
    end

    def fetch_manifests(coords, branch)
      MANIFEST_PATHS.each_with_object({}) do |path, manifests|
        content = fetch_content(coords, path, branch)
        manifests[path] = content if content.present?
      end
    end

    def fetch_readme(coords)
      response = get("/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/readme", allow_not_found: true)
      decode_content(response)
    end

    def fetch_content(coords, path, branch)
      response = get(
        "/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/contents/#{escaped(path)}",
        { ref: branch },
        allow_not_found: true
      )
      decode_content(response)
    end

    def decode_content(response)
      return nil unless response.is_a?(Hash)
      return nil unless response["encoding"] == "base64"

      decoded = Base64.decode64(response["content"].to_s)
      return nil if decoded.bytesize > CONTENT_MAX_BYTES

      decoded.force_encoding("UTF-8").scrub
    rescue ArgumentError
      nil
    end

    def get(path, params = {}, allow_not_found: false, **query_params)
      uri = URI(API_BASE + path)
      query = (params.is_a?(Hash) ? params : {}).merge(query_params)
      uri.query = URI.encode_www_form(query) if query.present?

      response = connection.get(uri.request_uri, nil, headers)
      if response.status == 401 && oauth_token.blank? && GitHubContextService.api_token.present?
        Rails.logger.warn("GitHubInsights::FetchService global GITHUB_TOKEN was rejected; retrying without Authorization header.")
        response = connection.get(uri.request_uri, nil, base_headers)
      end
      return response.body if response.success?

      case response.status
      when 401
        raise AuthenticationError, "GitHub authentication failed. Reconnect GitHub OAuth or check the configured GITHUB_TOKEN."
      when 404
        return nil if allow_not_found

        raise RepositoryNotFoundError, "Repository not found or not publicly accessible."
      when 403
        raise GitHubRateLimitError, "GitHub API rate limit reached. Try again shortly."
      when 500..599
        raise TemporaryFetchError, "GitHub request failed (HTTP #{response.status})."
      else
        raise FetchError, "GitHub request failed (HTTP #{response.status})."
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
      base = base_headers
      token = oauth_token || GitHubContextService.api_token
      base["Authorization"] = "Bearer #{token}" if token.present?
      base
    end

    def base_headers
      {
        "Accept" => "application/vnd.github+json",
        "X-GitHub-Api-Version" => "2022-11-28"
      }
    end

    def oauth_token
      @oauth_token
    end

    def escaped(value)
      URI.encode_www_form_component(value.to_s)
    end
  end
end
