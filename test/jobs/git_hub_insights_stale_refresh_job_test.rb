require "test_helper"

class GitHubInsightsStaleRefreshJobTest < ActiveJob::TestCase
  test "enqueues light sync for stale ready project" do
    project = projects(:test_project_one)
    project.update_columns(
      source_code_url: "https://github.com/rails/rails",
      github_insights_enabled: true,
      github_insights_sync_status: "ready",
      github_insights_last_synced_at: 10.days.ago
    )

    assert_enqueued_with(job: GitHubInsightsSyncJob, args: [project.id, { sync_type: "light", source: "auto" }]) do
      GitHubInsightsStaleRefreshJob.perform_now
    end
  end

  test "enqueues deep sync for never-synced project" do
    project = projects(:test_project_one)
    project.update_columns(
      source_code_url: "https://github.com/rails/rails",
      github_insights_enabled: true,
      github_insights_sync_status: "never",
      github_insights_last_synced_at: nil
    )

    assert_enqueued_with(job: GitHubInsightsSyncJob, args: [project.id, { sync_type: "deep", source: "auto" }]) do
      GitHubInsightsStaleRefreshJob.perform_now
    end
  end

  test "skips projects already queued or syncing" do
    queued_project = projects(:test_project_one)
    queued_project.update_columns(
      source_code_url: "https://github.com/rails/rails",
      github_insights_enabled: true,
      github_insights_sync_status: "queued",
      github_insights_last_synced_at: 10.days.ago
    )

    syncing_project = projects(:test_project_two)
    syncing_project.update_columns(
      source_code_url: "https://github.com/rails/rails",
      github_insights_enabled: true,
      github_insights_sync_status: "syncing",
      github_insights_last_synced_at: 10.days.ago
    )

    assert_no_enqueued_jobs only: GitHubInsightsSyncJob do
      GitHubInsightsStaleRefreshJob.perform_now
    end
  end

  test "skips projects without github insights enabled or without github url" do
    project = projects(:test_project_one)
    project.update_columns(
      github_insights_enabled: false,
      source_code_url: "https://github.com/rails/rails",
      github_insights_sync_status: "ready",
      github_insights_last_synced_at: 10.days.ago
    )

    no_url_project = projects(:test_project_two)
    no_url_project.update_columns(
      github_insights_enabled: true,
      source_code_url: nil,
      github_url: nil,
      github_insights_sync_status: "ready",
      github_insights_last_synced_at: 10.days.ago
    )

    assert_no_enqueued_jobs only: GitHubInsightsSyncJob do
      GitHubInsightsStaleRefreshJob.perform_now
    end
  end
end
