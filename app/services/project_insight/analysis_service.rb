# frozen_string_literal: true

module ProjectInsight
  # Builds a compact, cached, evidence-friendly analysis snapshot for a project repository.
  class AnalysisService
    API_BASE = "https://api.github.com"
    ANALYSIS_TTL = 24.hours
    COMMITS_LIMIT = 30
    TREE_LIMIT = 200
    CONTENT_MAX_BYTES = 60_000
    MANIFEST_PATHS = [
      "Gemfile",
      "Gemfile.lock",
      "package.json",
      "yarn.lock",
      "pnpm-lock.yaml",
      "requirements.txt",
      "pyproject.toml",
      "go.mod"
    ].freeze

    class AnalysisError < StandardError; end
    class RepositoryNotFoundError < AnalysisError; end
    class GitHubRateLimitError < AnalysisError; end

    def self.refresh!(project)
      new.refresh!(project)
    end

    def self.fetch(project, force_refresh: false)
      new.fetch(project, force_refresh: force_refresh)
    end

    def fetch(project, force_refresh: false)
      return {} unless project.project_insight_ready?

      existing = project.project_insight_analysis

      unless force_refresh
        if existing.present? && !stale?(project)
          return existing
        end
      end

      refresh!(project)
    rescue AnalysisError
      return existing if existing.present?

      raise
    end

    def refresh!(project)
      coords = project.github_repo_coordinates
      return {} if coords.blank?

      metadata = fetch_repo(coords)
      default_branch = metadata["default_branch"].presence || "main"
      languages = fetch_languages(coords)
      commits = fetch_commits(coords)
      tree = fetch_tree(coords, default_branch)
      manifests = fetch_manifests(coords, default_branch)
      readme = fetch_readme(coords)

      payload = build_snapshot(
        project: project,
        coords: coords,
        metadata: metadata,
        languages: languages,
        commits: commits,
        tree: tree,
        manifests: manifests,
        readme: readme
      )

      project.update!(
        project_insight_analysis: payload,
        project_insight_last_analyzed_at: Time.current
      )

      payload
    rescue AnalysisError => e
      Rails.logger.warn "ProjectInsight::AnalysisService failed for project #{project.id}: #{e.message}"
      raise
    rescue Faraday::Error => e
      Rails.logger.warn "ProjectInsight::AnalysisService failed for project #{project.id}: #{e.message}"
      raise AnalysisError, "GitHub request failed. Please try again."
    end

    private

    def stale?(project)
      analyzed_at = project.project_insight_last_analyzed_at
      analyzed_at.blank? || analyzed_at < ANALYSIS_TTL.ago
    end

    def build_snapshot(project:, coords:, metadata:, languages:, commits:, tree:, manifests:, readme:)
      architecture = infer_architecture(tree:, manifests:, readme:)
      maintenance = infer_maintenance(commits: commits, metadata: metadata)
      complexity = infer_complexity(tree: tree, manifests: manifests)

      {
        "repo" => {
          "owner" => coords[:owner],
          "name" => coords[:repo],
          "full_name" => metadata["full_name"],
          "html_url" => metadata["html_url"],
          "description" => metadata["description"],
          "default_branch" => metadata["default_branch"],
          "stars" => metadata["stargazers_count"],
          "forks" => metadata["forks_count"],
          "open_issues" => metadata["open_issues_count"],
          "created_at" => metadata["created_at"],
          "updated_at" => metadata["updated_at"],
          "pushed_at" => metadata["pushed_at"]
        }.compact,
        "languages" => languages,
        "architecture" => architecture,
        "maintenance" => maintenance,
        "complexity" => complexity,
        "dependencies" => manifests.transform_values { |v| summarize_manifest(v) },
        "readme_excerpt" => readme.to_s[0, 1500],
        "evidence" => build_evidence(metadata:, commits:, tree:, manifests:, languages:)
      }
    end

    def infer_architecture(tree:, manifests:, readme:)
      top_dirs = tree.map { |path| path.split("/").first }.uniq.first(12)
      backend = manifests.key?("Gemfile") || manifests.key?("requirements.txt") || manifests.key?("go.mod")
      frontend = manifests.key?("package.json")
      monorepo = top_dirs.include?("apps") || top_dirs.include?("packages")

      {
        "top_level_directories" => top_dirs,
        "backend_present" => backend,
        "frontend_present" => frontend,
        "monorepo_pattern" => monorepo,
        "readme_mentions" => extract_readme_signals(readme)
      }
    end

    def infer_maintenance(commits:, metadata:)
      latest_commit = commits.first
      contributors = commits.map { |c| c.dig("author", "login") || c.dig("commit", "author", "name") }.compact.uniq

      {
        "recent_commit_count" => commits.length,
        "latest_commit_at" => latest_commit&.dig("commit", "author", "date"),
        "unique_recent_contributors" => contributors.length,
        "repo_pushed_at" => metadata["pushed_at"]
      }
    end

    def infer_complexity(tree:, manifests:)
      test_files = tree.count { |path| path.match?(/(^|\/)(test|spec|__tests__)\//) }
      service_files = tree.count { |path| path.include?("/services/") }
      migration_files = tree.count { |path| path.match?(/db\/migrate\//) }

      {
        "file_count_sampled" => tree.length,
        "test_file_count" => test_files,
        "service_file_count" => service_files,
        "migration_file_count" => migration_files,
        "has_lockfiles" => manifests.keys.any? { |k| k.end_with?(".lock") || k.include?("lock") }
      }
    end

    def build_evidence(metadata:, commits:, tree:, manifests:, languages:)
      [
        { "type" => "repo_metadata", "data" => metadata.slice("full_name", "description", "default_branch", "pushed_at", "stargazers_count") },
        { "type" => "languages", "data" => languages.first(5) },
        { "type" => "commit_sample", "data" => commits.first(5).map { |c| c.slice("sha", "html_url").merge("message" => c.dig("commit", "message"), "date" => c.dig("commit", "author", "date")) } },
        { "type" => "tree_sample", "data" => tree.first(40) },
        { "type" => "dependency_manifests", "data" => manifests.keys }
      ]
    end

    def summarize_manifest(content)
      lines = content.to_s.lines.map(&:strip).reject(&:blank?)
      lines.first(40)
    end

    def extract_readme_signals(readme)
      return [] if readme.blank?

      readme
        .to_s
        .split(/\n+/)
        .map(&:strip)
        .select { |line| line.start_with?("#") || line.match?(/architecture|stack|deploy|test|ci|docker/i) }
        .first(8)
    end

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

    def fetch_commits(coords)
      response = get(
        "/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/commits",
        per_page: COMMITS_LIMIT
      )
      return [] unless response.is_a?(Array)

      response
    end

    def fetch_tree(coords, branch)
      response = get(
        "/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/git/trees/#{escaped(branch)}",
        recursive: 1
      )
      return [] unless response.is_a?(Hash)

      Array(response["tree"])
        .select { |node| node["type"] == "blob" }
        .map { |node| node["path"].to_s }
        .first(TREE_LIMIT)
    end

    def fetch_manifests(coords, branch)
      MANIFEST_PATHS.each_with_object({}) do |path, manifests|
        content = fetch_file(coords, path, branch)
        manifests[path] = content if content.present?
      end
    end

    def fetch_readme(coords)
      response = get(
        "/repos/#{escaped(coords[:owner])}/#{escaped(coords[:repo])}/readme",
        allow_not_found: true
      )
      decode_content(response)
    end

    def fetch_file(coords, path, branch)
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
      params = (params.is_a?(Hash) ? params : {}).merge(query_params)
      uri.query = URI.encode_www_form(params) if params.present?

      response = connection.get(uri.request_uri, nil, headers)
      return response.body if response.success?

      case response.status
      when 404
        return nil if allow_not_found

        raise RepositoryNotFoundError, "Repository not found or not publicly accessible."
      when 403
        raise GitHubRateLimitError, "GitHub API rate limit reached. Try again shortly."
      else
        raise AnalysisError, "GitHub request failed (HTTP #{response.status})."
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
      base = {
        "Accept" => "application/vnd.github+json",
        "X-GitHub-Api-Version" => "2022-11-28"
      }

      token = GitHubContextService.api_token
      base["Authorization"] = "Bearer #{token}" if token.present?
      base
    end

    def escaped(value)
      URI.encode_www_form_component(value.to_s)
    end
  end
end
