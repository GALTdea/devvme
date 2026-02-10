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

  test "emits stale refresh instrumentation payload" do
    project = projects(:test_project_one)
    project.update_columns(
      source_code_url: "https://github.com/rails/rails",
      github_insights_enabled: true,
      github_insights_sync_status: "never",
      github_insights_last_synced_at: nil
    )

    events = []
    subscriber = ActiveSupport::Notifications.subscribe("github_insights.stale_refresh") do |_name, _start, _finish, _id, payload|
      events << payload
    end

    GitHubInsightsStaleRefreshJob.perform_now

    assert_equal 1, events.size
    assert events.first[:scanned_count].to_i >= 1
    assert events.first[:queued_count].to_i >= 1
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  test "internal rollout only queues admin-owned projects" do
    regular_project = projects(:test_project_one)
    regular_project.update_columns(
      source_code_url: "https://github.com/rails/rails",
      github_insights_enabled: true,
      github_insights_sync_status: "never",
      github_insights_last_synced_at: nil
    )

    admin = users(:test_admin)
    admin.update!(account_status: :active)
    admin_project = admin.projects.create!(
      title: "Admin GitHub Project",
      description: "admin owned",
      technologies_used: ["Ruby"],
      status: :published,
      source_code_url: "https://github.com/rails/rails"
    )
    admin_project.update_columns(
      github_insights_enabled: true,
      github_insights_sync_status: "never",
      github_insights_last_synced_at: nil
    )

    with_github_enrichment_rollout("internal") do
      assert_enqueued_with(job: GitHubInsightsSyncJob, args: [admin_project.id, { sync_type: "deep", source: "auto" }]) do
        GitHubInsightsStaleRefreshJob.perform_now
      end
    end
  end

  private

  def with_github_enrichment_rollout(value)
    original = ENV["GITHUB_PROJECT_ENRICHMENT_ROLLOUT"]
    ENV["GITHUB_PROJECT_ENRICHMENT_ROLLOUT"] = value
    yield
  ensure
    ENV["GITHUB_PROJECT_ENRICHMENT_ROLLOUT"] = original
  end
end
