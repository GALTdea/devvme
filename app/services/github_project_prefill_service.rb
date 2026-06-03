# frozen_string_literal: true

class GitHubProjectPrefillService
  README_EXCERPT_MAX = 400
  TECHNOLOGY_LIMIT = 10

  class PrefillError < StandardError; end

  PREFILL_STORY_FIELDS = %w[overview technical_decisions demonstrates].freeze

  def self.call(user:, repository_url:)
    new(user: user).call(repository_url: repository_url)
  end

  def initialize(user:)
    @user = user
  end

  def call(repository_url:)
    identity = GitHubInsights::RepoResolver.resolve!(repository_url)
    raw_payload = fetch_payload(identity)
    repo = raw_payload["repo"] || {}
    build_response(identity:, repo:, raw_payload:)
  rescue GitHubInsights::RepoResolver::InvalidRepositoryUrlError => e
    raise PrefillError, e.message
  rescue GitHubInsights::FetchService::AuthenticationError
    raise PrefillError, "GitHub authentication failed. Connect GitHub to import private repositories."
  rescue GitHubInsights::FetchService::GitHubRateLimitError
    raise PrefillError, "GitHub API rate limit reached. Try again in a few minutes or connect GitHub."
  rescue GitHubInsights::FetchService::RepositoryNotFoundError
    raise PrefillError, private_or_missing_message(identity)
  rescue GitHubInsights::FetchService::FetchError => e
    raise PrefillError, e.message
  end

  private

  attr_reader :user

  def fetch_payload(identity)
    GitHubInsights::FetchService.call(
      owner: identity[:owner],
      repo: identity[:repo],
      sync_type: "light",
      oauth_token: user.github_oauth_token_for_insights
    )
  end

  def private_or_missing_message(_identity = nil)
    if user.github_oauth_connected?
      "Repository not found or you do not have access to it."
    else
      "Repository not found or is private. Connect GitHub to import private repositories."
    end
  end

  def build_response(identity:, repo:, raw_payload:)
    languages = Array(raw_payload["languages"])
    tree_paths = Array(raw_payload["tree_paths"])
    manifests = raw_payload["manifests"].is_a?(Hash) ? raw_payload["manifests"] : {}
    signals = architecture_signals(tree_paths:, manifests:)

    description = repo["description"].to_s.presence || readme_excerpt(raw_payload["readme"])
    technologies = build_technologies(languages:, repo:, manifests:)
    enrichment_enabled = FeatureFlags.github_project_enrichment_enabled_for?(user)

    project_attrs = {
      "title" => humanized_title(repo["name"]),
      "description" => description,
      "source_code_url" => identity[:canonical_url],
      "live_url" => valid_homepage(repo["homepage"]),
      "technologies_display" => technologies.join(", "),
      "project_insight_enabled" => true
    }
    project_attrs["github_insights_enabled"] = true if enrichment_enabled

    story_attrs = {
      "overview" => description,
      "technical_decisions" => build_technical_decisions(signals:, manifests:, languages:),
      "demonstrates" => build_demonstrates(languages:, signals:)
    }

    {
      "repository" => {
        "owner" => identity[:owner],
        "name" => identity[:repo],
        "full_name" => "#{identity[:owner]}/#{identity[:repo]}",
        "canonical_url" => identity[:canonical_url],
        "private" => repo["private"] == true,
        "homepage" => valid_homepage(repo["homepage"]),
        "pushed_at" => repo["pushed_at"]
      },
      "project" => project_attrs,
      "project_story" => story_attrs,
      "evidence" => build_evidence(languages:, repo:, signals:, manifests:),
      "warnings" => []
    }
  end

  def humanized_title(name)
    name.to_s.tr("-_", " ").split.map(&:capitalize).join(" ")
  end

  def valid_homepage(url)
    value = url.to_s.strip
    return nil if value.blank?

    normalized = value.match?(/\A[a-z][a-z0-9+.-]*:/i) ? value : "https://#{value}"
    uri = URI.parse(normalized)
    return normalized if uri.host.present?

    nil
  rescue URI::InvalidURIError
    nil
  end

  def readme_excerpt(readme)
    return nil if readme.blank?

    text = readme.to_s
                 .gsub(/!\[[^\]]*\]\([^)]*\)/, "")
                 .gsub(/\[([^\]]+)\]\([^)]+\)/, "\\1")
                 .gsub(/[#*_`>|]/, " ")
                 .squish
    return nil if text.blank?

    excerpt = text[0, README_EXCERPT_MAX]
    excerpt += "…" if text.length > README_EXCERPT_MAX
    excerpt
  end

  def build_technologies(languages:, repo:, manifests:)
    names = []
    names.concat(languages.map { |entry| entry["name"] })
    names.concat(Array(repo["topics"]))
    names.concat(manifest_technology_hints(manifests))
    names.map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(TECHNOLOGY_LIMIT)
  end

  def manifest_technology_hints(manifests)
    hints = []
    hints << "Ruby" if manifests.key?("Gemfile")
    hints << "Rails" if manifests["Gemfile"].to_s.include?("rails")
    hints << "JavaScript" if manifests.key?("package.json")
    hints << "Docker" if manifests.key?("Dockerfile")
    hints << "GitHub Actions" if manifests.key?(".github/workflows")
    hints
  end

  def architecture_signals(tree_paths:, manifests:)
    {
      "has_ci" => tree_paths.any? { |path| path.start_with?(".github/workflows/") },
      "has_docker" => tree_paths.include?("Dockerfile") || manifests.key?("Dockerfile"),
      "has_tests_directory" => tree_paths.any? { |path| path.match?(/(^|\/)(test|spec|__tests__)\//) },
      "monorepo_pattern" => tree_paths.any? { |path| path.start_with?("apps/", "packages/") }
    }
  end

  def build_technical_decisions(signals:, manifests:, languages:)
    notes = []
    manifest_names = manifests.keys.sort
    notes << "Detected tooling from repository manifests: #{manifest_names.join(', ')}." if manifest_names.any?

    language_names = languages.map { |entry| entry["name"] }.compact
    notes << "Primary languages from GitHub: #{language_names.join(', ')}." if language_names.any?

    notes << "CI workflow files are present in the repository." if signals["has_ci"]
    notes << "Docker configuration is present in the repository." if signals["has_docker"]
    notes << "Automated test directories are present in the repository." if signals["has_tests_directory"]
    notes << "Monorepo-style app/package layout detected." if signals["monorepo_pattern"]

    notes.first(4).join(" ")
  end

  def build_demonstrates(languages:, signals:)
    language_names = languages.map { |entry| entry["name"] }.compact
    parts = []
    parts << "Shows #{language_names.join(', ')} project work" if language_names.any?
    parts << "with testing-oriented repository structure" if signals["has_tests_directory"]
    parts << "and deployment/CI-oriented setup" if signals["has_ci"] || signals["has_docker"]
    parts.join(" ").strip.presence || "Shows repository-backed development work grounded in GitHub signals."
  end

  def build_evidence(languages:, repo:, signals:, manifests:)
    evidence = []
    language_names = languages.map { |entry| entry["name"] }.compact
    if language_names.any?
      evidence << {
        "field" => "technologies_display",
        "source" => "github_languages",
        "summary" => "#{language_names.join(' and ')} detected by GitHub language stats."
      }
    end

    if repo["description"].present?
      evidence << {
        "field" => "description",
        "source" => "github_repo_description",
        "summary" => "Repository description from GitHub metadata."
      }
    end

    if signals["has_ci"] || manifests.key?(".github/workflows")
      evidence << {
        "field" => "project_story[technical_decisions]",
        "source" => "github_repository_structure",
        "summary" => "CI workflow files detected in the repository tree."
      }
    end

    evidence
  end
end
