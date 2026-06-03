require "test_helper"

module GitHubProject
  class RepositoryListServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:test_user_one)
      @user.update!(
        github_oauth_token: "test-token",
        github_oauth_connected_at: Time.current
      )
      Rails.cache.clear
    end

    test "requires github oauth connection" do
      @user.update!(github_oauth_token: nil, github_oauth_connected_at: nil)

      assert_raises(RepositoryListService::NotConnectedError) do
        RepositoryListService.call(user: @user)
      end
    end

    test "returns owner repositories and hides forks by default" do
      service = RepositoryListService.new(user: @user)
      service.define_singleton_method(:get) do |path, _params = {}|
        assert_equal "/user/repos", path
        [
          {
            "full_name" => "alice/main-app",
            "html_url" => "https://github.com/alice/main-app",
            "description" => "Main app",
            "private" => false,
            "fork" => false,
            "archived" => false,
            "language" => "Ruby",
            "pushed_at" => "2026-06-02T10:00:00Z"
          },
          {
            "full_name" => "alice/forked-lib",
            "html_url" => "https://github.com/alice/forked-lib",
            "description" => "Fork",
            "private" => false,
            "fork" => true,
            "archived" => false,
            "language" => "Ruby",
            "pushed_at" => "2026-06-03T10:00:00Z"
          }
        ]
      end

      repos = service.call
      assert_equal 1, repos.size
      assert_equal "alice/main-app", repos.first["full_name"]
    end

    test "includes forks when requested" do
      service = RepositoryListService.new(user: @user, include_forks: true)
      service.define_singleton_method(:get) { |_path, _params = {}| [{ "full_name" => "alice/fork", "fork" => true, "html_url" => "https://github.com/alice/fork" }] }

      repos = service.call
      assert_equal 1, repos.size
      assert repos.first["fork"]
    end

    test "caches normalized repository list per user" do
      calls = 0
      original = RepositoryListService.instance_method(:fetch_repositories)
      RepositoryListService.define_method(:fetch_repositories) do
        calls += 1
        [
          {
            "full_name" => "alice/cached",
            "url" => "https://github.com/alice/cached",
            "description" => nil,
            "private" => false,
            "fork" => false,
            "archived" => false,
            "language" => nil,
            "pushed_at" => nil
          }
        ]
      end

      2.times { RepositoryListService.call(user: @user) }
      assert_equal 1, calls

      RepositoryListService.call(user: @user, force_refresh: true)
      assert_equal 2, calls
    ensure
      RepositoryListService.define_method(:fetch_repositories, original)
    end
  end
end
