require "test_helper"

class GitHubInsightsPublicPageTest < ActionDispatch::IntegrationTest
  test "public page shows github insights cards when ready summary exists" do
    project = projects(:test_project_one)
    project.update_columns(
      status: Project.statuses[:published],
      github_insights_enabled: true,
      github_insights_sync_status: "ready",
      github_insights_summary: {
        "project_overview" => {
          "stars" => 9,
          "forks" => 2,
          "open_issues_count" => 1,
          "default_branch" => "main"
        },
        "tech_stack" => {
          "languages" => [{ "name" => "Ruby" }],
          "manifests_detected" => ["Gemfile"]
        },
        "activity_ownership" => {
          "commit_count_sampled" => 10,
          "active_contributors_sampled" => 1,
          "top_contributor_commit_share_percent" => 100.0
        },
        "issues_prs" => {
          "issues_open_count" => 1,
          "issues_closed_count" => 3,
          "prs_open_count" => 0,
          "prs_closed_count" => 4,
          "prs_merged_count" => 4
        },
        "highlights" => ["Recent activity detected"],
        "caveats" => ["Bounded sample"]
      }
    )

    get public_project_path(project)
    assert_response :success
    assert_select "h3", text: /GitHub Project Signals/i
    assert_select "h4", text: /Project Overview/i
    assert_select "h4", text: /Evidence Highlights/i
  end
end
