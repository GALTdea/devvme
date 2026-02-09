require "test_helper"

module GitHubInsights
  class ComputeServiceTest < ActiveSupport::TestCase
    test "computes grouped metrics, highlights, caveats, and confidence" do
      project = projects(:test_project_one)

      raw_payload = {
        "sync_type" => "deep",
        "repo" => {
          "name" => "project-one",
          "description" => "Demo project",
          "stargazers_count" => 12,
          "forks_count" => 4,
          "subscribers_count" => 3,
          "open_issues_count" => 5,
          "topics" => ["rails", "postgres"],
          "default_branch" => "main",
          "created_at" => "2025-01-01T00:00:00Z",
          "pushed_at" => "2026-02-01T00:00:00Z",
          "license" => { "spdx_id" => "MIT" }
        },
        "languages" => [{ "name" => "Ruby", "bytes" => 1000, "share" => 80.0 }],
        "tree_paths" => ["app/models/project.rb", "spec/models/project_spec.rb", ".github/workflows/ci.yml", "Dockerfile"],
        "manifests" => { "Gemfile" => "source 'https://rubygems.org'" },
        "readme" => "Install and setup instructions",
        "commits" => [
          { "author" => { "login" => "alice" }, "commit" => { "author" => { "date" => "2026-02-01T00:00:00Z", "name" => "Alice" } } },
          { "author" => { "login" => "bob" }, "commit" => { "author" => { "date" => "2026-01-28T00:00:00Z", "name" => "Bob" } } },
          { "author" => { "login" => "alice" }, "commit" => { "author" => { "date" => "2026-01-27T00:00:00Z", "name" => "Alice" } } }
        ],
        "issues" => [
          { "state" => "closed", "created_at" => "2026-01-01T00:00:00Z", "closed_at" => "2026-01-02T00:00:00Z" },
          { "state" => "open", "created_at" => "2026-01-10T00:00:00Z", "closed_at" => nil }
        ],
        "pull_requests" => [
          { "state" => "closed", "created_at" => "2026-01-01T00:00:00Z", "merged_at" => "2026-01-03T00:00:00Z", "review_comments" => 1, "comments" => 0 },
          { "state" => "open", "created_at" => "2026-01-04T00:00:00Z", "merged_at" => nil, "review_comments" => 0, "comments" => 0 }
        ],
        "contributors" => [{ "login" => "alice" }, { "login" => "bob" }],
        "releases" => [{ "tag_name" => "v1.0.0" }]
      }

      result = GitHubInsights::ComputeService.call(
        project: project,
        repo_identity: { owner: "example", repo: "project-one", canonical_url: "https://github.com/example/project-one" },
        raw_payload: raw_payload
      )

      assert_equal "project-one", result.dig("metrics", "project_overview", "name")
      assert_equal 3, result.dig("metrics", "activity_ownership", "commit_count_sampled")
      assert_equal 2, result.dig("metrics", "issues_prs", "prs_open_count") + result.dig("metrics", "issues_prs", "prs_closed_count")
      assert result["highlights"].any?
      assert result["confidence"].key?("tech_stack")
      assert result.dig("summary", "project_overview").present?
    end
  end
end
