require "test_helper"

module GitHubInsights
  class SyncServiceTest < ActiveSupport::TestCase
    test "runs sync and persists snapshot and summary" do
      project = projects(:test_project_one)

      resolver = Class.new do
        def self.resolve_project!(_project)
          { owner: "example", repo: "demo", canonical_url: "https://github.com/example/demo" }
        end
      end

      fetcher = Class.new do
        def self.call(owner:, repo:, sync_type:)
          {
            "repo" => { "name" => repo, "stargazers_count" => 1, "forks_count" => 0, "open_issues_count" => 0 },
            "languages" => [],
            "tree_paths" => [],
            "manifests" => {},
            "readme" => nil,
            "commits" => [],
            "issues" => [],
            "pull_requests" => [],
            "contributors" => [],
            "releases" => [],
            "sync_type" => sync_type,
            "owner" => owner
          }
        end
      end

      computer = Class.new do
        def self.call(project:, repo_identity:, raw_payload:)
          {
            "summary" => { "project_overview" => { "name" => project.title }, "highlights" => ["ok"], "caveats" => [] },
            "metrics" => { "project_overview" => { "name" => raw_payload.dig("repo", "name") } },
            "highlights" => ["ok"],
            "caveats" => [],
            "confidence" => { "overview" => 1.0 }
          }
        end
      end

      result = GitHubInsights::SyncService.new(
        repo_resolver: resolver,
        fetch_service: fetcher,
        compute_service: computer
      ).call(project: project, sync_type: "deep", source: "manual")

      assert_equal "ready", result["status"]
      assert_equal "ready", project.reload.github_insights_sync_status
      assert project.github_insights_last_synced_at.present?
      assert_equal project.title, project.github_insights_summary.dig("project_overview", "name")
      assert_equal 1, project.project_github_insight_snapshots.count
      snapshot = project.project_github_insight_snapshots.order(:created_at).last
      assert_equal "deep", snapshot.sync_type
      assert_equal "manual", snapshot.source
    end

    test "returns skipped when project is already syncing" do
      project = projects(:test_project_one)
      project.update!(github_insights_sync_status: "syncing")

      resolver = Class.new do
        def self.resolve_project!(_project)
          raise "should not run"
        end
      end

      result = GitHubInsights::SyncService.new(
        repo_resolver: resolver,
        fetch_service: Class.new,
        compute_service: Class.new
      ).call(project: project, sync_type: "light", source: "auto")

      assert_equal "skipped", result["status"]
      assert_equal "sync_in_progress", result["reason"]
    end
  end
end
