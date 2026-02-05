# frozen_string_literal: true

require "test_helper"

class GitHubSnapshotServiceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  def setup
    @user = User.create!(
      email: "github_snapshot@example.com",
      password: "password123",
      username: "githubsnapshot",
      full_name: "GitHub Snapshot User",
      github_url: "https://github.com/johndoe"
    )
    @user.update!(account_status: :active)
  end

  test "returns nil when user has no github_url" do
    @user.update_column(:github_url, nil)
    assert_nil GitHubSnapshotService.fetch_for_user(@user)
  end

  test "creates snapshot and returns payload" do
    payload = { "profile" => { "login" => "johndoe" }, "repos" => [] }
    with_stubbed_fetch(payload) do
      result = GitHubSnapshotService.fetch_for_user(@user)
      assert_equal payload, result
      assert_equal "johndoe", @user.github_profile_snapshot.reload.username
    end
  end

  test "reuses fresh snapshot without refetching" do
    snapshot = @user.create_github_profile_snapshot!(
      username: "johndoe",
      payload: { "profile" => { "login" => "johndoe" } },
      fetched_at: 1.hour.ago
    )

    with_stubbed_fetch(->(*) { raise "should not fetch" }) do
      result = GitHubSnapshotService.fetch_for_user(@user)
      assert_equal snapshot.payload, result
    end
  end

  test "refreshes stale snapshot" do
    snapshot = @user.create_github_profile_snapshot!(
      username: "johndoe",
      payload: { "profile" => { "login" => "old" } },
      fetched_at: 2.days.ago
    )
    payload = { "profile" => { "login" => "new" } }

    with_stubbed_fetch(payload) do
      result = GitHubSnapshotService.fetch_for_user(@user)
      assert_equal "new", result.dig("profile", "login")
      assert_equal "new", snapshot.reload.payload.dig("profile", "login")
    end
  end

  private

  def with_stubbed_fetch(value)
    original = GitHubContextService.method(:fetch_for_username)
    GitHubContextService.define_singleton_method(:fetch_for_username) do |*args|
      value.respond_to?(:call) ? value.call(*args) : value
    end
    yield
  ensure
    GitHubContextService.define_singleton_method(:fetch_for_username, original)
  end
end
