require "test_helper"

class GitHubProjectPrefillServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:test_user_one)
  end

  test "returns form-ready prefill payload from github data" do
    payload = stubbed_prefill(
      repo: {
        "name" => "devproof-app",
        "description" => "Proof of work app",
        "homepage" => "https://devproof.example.com",
        "topics" => ["rails"],
        "private" => false,
        "pushed_at" => "2026-06-01T12:00:00Z"
      },
      languages: [{ "name" => "Ruby", "bytes" => 700, "share" => 70.0 }],
      tree_paths: [".github/workflows/ci.yml", "spec/models/project_spec.rb", "Gemfile"],
      manifests: { "Gemfile" => "gem 'rails'" }
    )

    assert_equal "Devproof App", payload.dig("project", "title")
    assert_equal "Proof of work app", payload.dig("project", "description")
    assert_equal "https://github.com/acme/devproof-app", payload.dig("project", "source_code_url")
    assert_equal "https://devproof.example.com", payload.dig("project", "live_url")
    assert_includes payload.dig("project", "technologies_display"), "Ruby"
    assert_equal true, payload.dig("project", "project_insight_enabled")
    assert payload.dig("project_story", "overview").present?
    assert payload.dig("project_story", "technical_decisions").present?
    assert payload.dig("evidence").any?
  end

  test "uses readme excerpt when repo description is blank" do
    payload = stubbed_prefill(
      repo: { "name" => "demo", "description" => nil },
      readme: "# Demo App\n\nA portfolio project for developers."
    )

    assert_includes payload.dig("project", "description"), "portfolio project"
    assert_equal payload.dig("project", "description"), payload.dig("project_story", "overview")
  end

  test "raises friendly error for invalid repository url" do
    error = assert_raises(GitHubProjectPrefillService::PrefillError) do
      GitHubProjectPrefillService.call(user: @user, repository_url: "https://gitlab.com/acme/demo")
    end

    assert_match(/github\.com/i, error.message)
  end

  test "raises friendly error when repository is inaccessible" do
    with_stubbed_fetch(->(**_) { raise GitHubInsights::FetchService::RepositoryNotFoundError }) do
      error = assert_raises(GitHubProjectPrefillService::PrefillError) do
        GitHubProjectPrefillService.call(user: @user, repository_url: "https://github.com/acme/private-repo")
      end

      assert_match(/private|not found|access/i, error.message)
    end
  end

  private

  def stubbed_prefill(repo:, languages: [], readme: nil, tree_paths: [], manifests: {})
    raw_payload = {
      "repo" => repo,
      "languages" => languages,
      "readme" => readme,
      "tree_paths" => tree_paths,
      "manifests" => manifests,
      "commits" => [],
      "sync_type" => "light"
    }

    with_stubbed_fetch(->(**_) { raw_payload }) do
      GitHubProjectPrefillService.call(
        user: @user,
        repository_url: "https://github.com/acme/#{repo.fetch('name', 'demo')}"
      )
    end
  end

  def with_stubbed_fetch(payload_proc)
    original = GitHubInsights::FetchService.method(:call)
    GitHubInsights::FetchService.singleton_class.define_method(:call, payload_proc)
    yield
  ensure
    GitHubInsights::FetchService.singleton_class.define_method(:call, original)
  end
end
