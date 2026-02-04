# frozen_string_literal: true

# Fetches public GitHub profile, repos, and README snippets for Career Architect context.
# Uses URL-based fetch (user's github_url); optional GITHUB_TOKEN in ENV/credentials for higher rate limits.
class GitHubContextService
  API_BASE = "https://api.github.com"
  REPOS_PER_PAGE = 10
  READMES_PER_USER = 3
  README_MAX_CHARS = 1500
  CACHE_TTL = 1.hour

  class FetchError < StandardError; end

  def self.fetch_for_user(user)
    new.fetch_for_user(user)
  end

  def fetch_for_user(user)
    return nil if user.github_url.blank?

    username = extract_username(user.github_url)
    return nil if username.blank?

    cache_key = "architect:github:#{username}"
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      fetch_github_context(username)
    end
  rescue FetchError, Faraday::Error => e
    Rails.logger.warn "GitHubContextService: skip context for #{user.github_url}: #{e.message}"
    nil
  end

  def self.api_token
    ENV["GITHUB_TOKEN"].to_s.strip.presence ||
      Rails.application.credentials.dig(:github, :token).to_s.strip.presence
  end

  private

  def extract_username(url)
    return nil if url.blank?
    # https://github.com/username, https://github.com/username/, github.com/username
    normalized = url.to_s.strip.downcase
    normalized = "https://#{normalized}" unless normalized.start_with?("http")
    uri = URI.parse(normalized) rescue nil
    return nil unless uri&.host.to_s.include?("github.com")
    path = uri.path.to_s.strip.gsub(%r{\A/}, "").split("/")
    path.first.presence
  end

  def fetch_github_context(username)
    profile = fetch_profile(username)
    repos = fetch_repos(username)
    readmes = fetch_readmes_for_repos(username, repos)
    {
      "profile" => profile,
      "repos" => repos,
      "readmes" => readmes
    }.compact
  end

  def fetch_profile(username)
    resp = get("/users/#{URI.encode_www_form_component(username)}")
    return nil unless resp.is_a?(Hash)
    {
      "login" => resp["login"],
      "name" => resp["name"],
      "bio" => resp["bio"],
      "company" => resp["company"],
      "location" => resp["location"],
      "blog" => resp["blog"],
      "public_repos" => resp["public_repos"]
    }.compact
  end

  def fetch_repos(username)
    resp = get("/users/#{URI.encode_www_form_component(username)}/repos",
               sort: "updated", per_page: REPOS_PER_PAGE)
    return [] unless resp.is_a?(Array)
    resp.map do |r|
      {
        "name" => r["name"],
        "description" => r["description"],
        "language" => r["language"],
        "stargazers_count" => r["stargazers_count"],
        "html_url" => r["html_url"]
      }.compact
    end
  end

  def fetch_readmes_for_repos(username, repos)
    return {} if repos.blank?
    readmes = {}
    repos.first(READMES_PER_USER).each do |repo|
      content = fetch_readme(username, repo["name"])
      readmes[repo["name"]] = content if content.present?
    end
    readmes
  end

  def fetch_readme(owner, repo)
    resp = get("/repos/#{URI.encode_www_form_component(owner)}/#{URI.encode_www_form_component(repo)}/readme")
    return nil unless resp.is_a?(Hash) && resp["content"].present?
    decoded = Base64.decode64(resp["content"].to_s)
    decoded.force_encoding("UTF-8").scrub
    decoded = decoded[0, README_MAX_CHARS] + "…" if decoded.length > README_MAX_CHARS
    decoded.strip.presence
  rescue ArgumentError
    nil
  end

  def get(path, params = {})
    uri = URI(API_BASE + path)
    uri.query = URI.encode_www_form(params) if params.present?
    conn = Faraday.new(url: API_BASE) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
    resp = conn.get(uri.request_uri, nil, headers)
    raise FetchError, "HTTP #{resp.status}" unless resp.success?
    resp.body
  end

  def headers
    h = {
      "Accept" => "application/vnd.github+json",
      "X-GitHub-Api-Version" => "2022-11-28"
    }
    token = self.class.api_token
    h["Authorization"] = "Bearer #{token}" if token.present?
    h
  end
end
