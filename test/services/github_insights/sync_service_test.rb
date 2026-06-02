require "test_helper"

module GitHubInsights
  class SyncServiceTest < ActiveSupport::TestCase
    test "runs sync and persists snapshot and summary" do
      project = projects(:test_project_one)
      events = []
      subscriber = ActiveSupport::Notifications.subscribe("github_insights.sync") do |_name, _start, _finish, _id, payload|
        events << payload
      end

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
      assert_equal 1, events.size
      assert_equal "success", events.first[:result]
      assert_equal project.id, events.first[:project_id]
      assert events.first[:duration_ms].is_a?(Integer)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
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

    test "maps repository not found to permanent sync error and marks project failed" do
      project = projects(:test_project_one)
      project.user.update_columns(github_oauth_token: nil)

      resolver = Class.new do
        def self.resolve_project!(_project)
          { owner: "example", repo: "missing", canonical_url: "https://github.com/example/missing" }
        end
      end

      fetcher = Class.new do
        def self.call(**)
          raise GitHubInsights::FetchService::RepositoryNotFoundError, "Repository not found"
        end
      end

      error = assert_raises(GitHubInsights::SyncService::PermanentSyncError) do
        GitHubInsights::SyncService.new(
          repo_resolver: resolver,
          fetch_service: fetcher,
          compute_service: Class.new
        ).call(project: project, sync_type: "deep", source: "manual")
      end

      assert_match(/Repository not found/i, error.message)
      assert_match(/Connect GitHub OAuth/i, error.message)
      assert_equal "failed", project.reload.github_insights_sync_status
      assert_match(/Repository not found/i, project.github_insights_last_error)
    end

    test "maps authentication failures to permanent sync error and marks project failed" do
      project = projects(:test_project_one)
      project.user.update_columns(github_oauth_token: nil)

      resolver = Class.new do
        def self.resolve_project!(_project)
          { owner: "example", repo: "private", canonical_url: "https://github.com/example/private" }
        end
      end

      fetcher = Class.new do
        def self.call(**)
          raise GitHubInsights::FetchService::AuthenticationError, "GitHub authentication failed."
        end
      end

      error = assert_raises(GitHubInsights::SyncService::PermanentSyncError) do
        GitHubInsights::SyncService.new(
          repo_resolver: resolver,
          fetch_service: fetcher,
          compute_service: Class.new
        ).call(project: project, sync_type: "deep", source: "manual")
      end

      assert_match(/authentication failed/i, error.message)
      assert_match(/Connect GitHub OAuth/i, error.message)
      assert_equal "failed", project.reload.github_insights_sync_status
      assert_match(/Connect GitHub OAuth/i, project.github_insights_last_error)
    end

    test "maps temporary upstream failure to retryable sync error and marks project failed" do
      project = projects(:test_project_one)
      events = []
      subscriber = ActiveSupport::Notifications.subscribe("github_insights.sync") do |_name, _start, _finish, _id, payload|
        events << payload
      end

      resolver = Class.new do
        def self.resolve_project!(_project)
          { owner: "example", repo: "demo", canonical_url: "https://github.com/example/demo" }
        end
      end

      fetcher = Class.new do
        def self.call(**)
          raise GitHubInsights::FetchService::TemporaryFetchError, "GitHub timeout"
        end
      end

      error = assert_raises(GitHubInsights::SyncService::RetryableSyncError) do
        GitHubInsights::SyncService.new(
          repo_resolver: resolver,
          fetch_service: fetcher,
          compute_service: Class.new
        ).call(project: project, sync_type: "light", source: "auto")
      end

      assert_match(/GitHub timeout/i, error.message)
      assert_equal "failed", project.reload.github_insights_sync_status
      assert_match(/GitHub timeout/i, project.github_insights_last_error)
      assert_equal 1, events.size
      assert_equal "failure", events.first[:result]
      assert_equal "retryable", events.first[:failure_type]
      assert_equal "GitHubInsights::FetchService::TemporaryFetchError", events.first[:error_class]
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    end
  end
end
