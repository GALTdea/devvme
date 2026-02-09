# frozen_string_literal: true

module GitHubInsights
  class ComputeService
    def self.call(project:, repo_identity:, raw_payload:)
      new.call(project:, repo_identity:, raw_payload:)
    end

    def call(project:, repo_identity:, raw_payload:)
      metrics = build_metrics(raw_payload)
      highlights = build_highlights(project: project, raw_payload: raw_payload, metrics: metrics)
      caveats = build_caveats(raw_payload: raw_payload, metrics: metrics)

      {
        "summary" => {
          "project_overview" => metrics["project_overview"],
          "tech_stack" => metrics["tech_stack"],
          "activity_ownership" => metrics["activity_ownership"],
          "issues_prs" => metrics["issues_prs"],
          "highlights" => highlights,
          "caveats" => caveats
        },
        "repo_identity" => {
          "owner" => repo_identity[:owner],
          "repo" => repo_identity[:repo],
          "canonical_url" => repo_identity[:canonical_url]
        },
        "metrics" => metrics,
        "highlights" => highlights,
        "caveats" => caveats,
        "confidence" => confidence_scores(raw_payload, metrics)
      }
    end

    private

    def build_metrics(raw_payload)
      repo = raw_payload["repo"] || {}
      commits = Array(raw_payload["commits"])
      pull_requests = Array(raw_payload["pull_requests"])
      issues = Array(raw_payload["issues"])
      contributors = Array(raw_payload["contributors"])
      languages = Array(raw_payload["languages"])
      tree_paths = Array(raw_payload["tree_paths"])
      manifests = raw_payload["manifests"].is_a?(Hash) ? raw_payload["manifests"] : {}

      {
        "project_overview" => {
          "name" => repo["name"],
          "description" => repo["description"],
          "stars" => repo["stargazers_count"].to_i,
          "forks" => repo["forks_count"].to_i,
          "watchers" => repo["subscribers_count"].to_i,
          "open_issues_count" => repo["open_issues_count"].to_i,
          "license" => repo.dig("license", "spdx_id"),
          "topics" => Array(repo["topics"]).first(10),
          "default_branch" => repo["default_branch"],
          "created_at" => repo["created_at"],
          "pushed_at" => repo["pushed_at"],
          "has_releases" => Array(raw_payload["releases"]).any?
        },
        "tech_stack" => {
          "languages" => languages.first(8),
          "manifests_detected" => manifests.keys.sort,
          "architecture_signals" => architecture_signals(tree_paths: tree_paths, manifests: manifests, readme: raw_payload["readme"])
        },
        "activity_ownership" => {
          "commit_count_sampled" => commits.size,
          "recent_commit_window_days" => 90,
          "latest_commit_at" => commits.first&.dig("commit", "author", "date"),
          "active_contributors_sampled" => active_contributors(commits).size,
          "top_contributor_commit_share_percent" => top_contributor_share_percent(commits),
          "contributors_listed_count" => contributors.size
        },
        "issues_prs" => {
          "issues_open_count" => issues.count { |issue| issue["state"] == "open" },
          "issues_closed_count" => issues.count { |issue| issue["state"] == "closed" },
          "median_issue_close_time_hours" => median_close_time_hours(issues),
          "prs_open_count" => pull_requests.count { |pr| pr["state"] == "open" },
          "prs_closed_count" => pull_requests.count { |pr| pr["state"] == "closed" },
          "prs_merged_count" => pull_requests.count { |pr| pr["merged_at"].present? },
          "median_pr_merge_time_hours" => median_pr_merge_time_hours(pull_requests),
          "prs_with_review_comments_count" => pull_requests.count { |pr| pr["review_comments"].to_i.positive? || pr["comments"].to_i.positive? }
        }
      }
    end

    def build_highlights(project:, raw_payload:, metrics:)
      overview = metrics["project_overview"]
      activity = metrics["activity_ownership"]
      issue_pr = metrics["issues_prs"]

      highlights = []
      highlights << "#{project.title}: #{overview['stars']} stars and #{overview['forks']} forks." if overview["stars"].positive? || overview["forks"].positive?

      if activity["commit_count_sampled"].positive?
        highlights << "Recent activity detected with #{activity['commit_count_sampled']} sampled commits and #{activity['active_contributors_sampled']} active contributors."
      end

      if issue_pr["prs_merged_count"].positive?
        highlights << "Pull request delivery signal: #{issue_pr['prs_merged_count']} merged PRs in the sampled window."
      end

      manifests = Array(metrics.dig("tech_stack", "manifests_detected"))
      if manifests.any?
        highlights << "Tooling evidence detected in manifests: #{manifests.first(3).join(', ')}."
      end

      if highlights.empty?
        highlights << "Repository data is available, but the sampled signals are limited for strong conclusions."
      end

      highlights.first(6)
    end

    def build_caveats(raw_payload:, metrics:)
      caveats = []
      caveats << "Issue and PR metrics are based on bounded recent samples, not full history." if raw_payload["sync_type"] == "deep"
      caveats << "Light sync mode collects baseline metadata and limited activity only." if raw_payload["sync_type"] == "light"
      caveats << "Contributor ownership can be skewed for solo-maintainer repositories." if metrics.dig("activity_ownership", "active_contributors_sampled").to_i <= 1
      caveats << "No release records were detected in the sampled data." unless metrics.dig("project_overview", "has_releases")
      caveats.uniq.first(5)
    end

    def confidence_scores(raw_payload, metrics)
      has_commits = Array(raw_payload["commits"]).any?
      has_issues = Array(raw_payload["issues"]).any?
      has_prs = Array(raw_payload["pull_requests"]).any?
      has_tree = Array(raw_payload["tree_paths"]).any?
      has_languages = Array(raw_payload["languages"]).any?

      {
        "overview" => score_for(metrics.dig("project_overview", "name").present?, has_languages),
        "tech_stack" => score_for(has_languages, has_tree),
        "activity_ownership" => score_for(has_commits, metrics.dig("activity_ownership", "active_contributors_sampled").to_i.positive?),
        "issues_prs" => score_for(has_issues, has_prs)
      }
    end

    def architecture_signals(tree_paths:, manifests:, readme:)
      {
        "has_ci" => tree_paths.any? { |path| path.start_with?(".github/workflows/") },
        "has_docker" => tree_paths.include?("Dockerfile") || manifests.key?("Dockerfile"),
        "has_tests_directory" => tree_paths.any? { |path| path.match?(/(^|\/)(test|spec|__tests__)\//) },
        "monorepo_pattern" => tree_paths.any? { |path| path.start_with?("apps/") || path.start_with?("packages/") },
        "readme_mentions_setup" => readme.to_s.match?(/install|setup|get started/i)
      }
    end

    def active_contributors(commits)
      commits.filter_map do |commit|
        commit.dig("author", "login").presence || commit.dig("commit", "author", "name").presence
      end.uniq
    end

    def top_contributor_share_percent(commits)
      contributors = commits.filter_map { |commit| commit.dig("author", "login").presence || commit.dig("commit", "author", "name").presence }
      return 0.0 if contributors.empty?

      counts = contributors.tally
      ((counts.values.max.to_f / contributors.size) * 100).round(2)
    end

    def median_close_time_hours(issues)
      closed_hours = issues.filter_map do |issue|
        next unless issue["state"] == "closed"
        next if issue["created_at"].blank? || issue["closed_at"].blank?

        ((Time.zone.parse(issue["closed_at"]) - Time.zone.parse(issue["created_at"])) / 1.hour).round(2)
      rescue StandardError
        nil
      end
      median(closed_hours)
    end

    def median_pr_merge_time_hours(pull_requests)
      merged_hours = pull_requests.filter_map do |pr|
        next if pr["created_at"].blank? || pr["merged_at"].blank?

        ((Time.zone.parse(pr["merged_at"]) - Time.zone.parse(pr["created_at"])) / 1.hour).round(2)
      rescue StandardError
        nil
      end
      median(merged_hours)
    end

    def median(values)
      entries = values.compact.sort
      return nil if entries.empty?

      mid = entries.length / 2
      return entries[mid] if entries.length.odd?

      ((entries[mid - 1] + entries[mid]) / 2.0).round(2)
    end

    def score_for(*signals)
      present_count = signals.count(true)
      (present_count.to_f / signals.length).round(2)
    end
  end
end
