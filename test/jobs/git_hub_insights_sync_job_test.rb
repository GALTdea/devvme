require "test_helper"

class GitHubInsightsSyncJobTest < ActiveJob::TestCase
  test "calls sync service with project and params" do
    project = projects(:test_project_one)
    calls = []

    original_call = GitHubInsights::SyncService.method(:call)
    GitHubInsights::SyncService.define_singleton_method(:call) do |project:, sync_type:, source:|
      calls << { project_id: project.id, sync_type: sync_type, source: source }
      { "status" => "ready" }
    end

    GitHubInsightsSyncJob.perform_now(project.id, sync_type: "deep", source: "manual")

    assert_equal 1, calls.size
    assert_equal project.id, calls.first[:project_id]
    assert_equal "deep", calls.first[:sync_type]
    assert_equal "manual", calls.first[:source]
  ensure
    GitHubInsights::SyncService.define_singleton_method(:call, original_call)
  end

  test "noops when project is missing" do
    assert_nothing_raised do
      GitHubInsightsSyncJob.perform_now(-999, sync_type: "light", source: "auto")
    end
  end
end
