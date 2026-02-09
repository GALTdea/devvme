require "test_helper"

module GitHubInsights
  class RepoResolverTest < ActiveSupport::TestCase
    test "resolves canonical github url with owner and repo" do
      resolved = GitHubInsights::RepoResolver.resolve!("github.com/rails/rails")

      assert_equal "rails", resolved[:owner]
      assert_equal "rails", resolved[:repo]
      assert_equal "https://github.com/rails/rails", resolved[:canonical_url]
    end

    test "supports urls with trailing .git and path suffix" do
      resolved = GitHubInsights::RepoResolver.resolve!("https://github.com/rails/rails.git/tree/main")

      assert_equal "rails", resolved[:owner]
      assert_equal "rails", resolved[:repo]
    end

    test "raises for non github host" do
      assert_raises(GitHubInsights::RepoResolver::InvalidRepositoryUrlError) do
        GitHubInsights::RepoResolver.resolve!("https://gitlab.com/rails/rails")
      end
    end

    test "resolves from project canonical repository helper" do
      project = projects(:test_project_one)
      project.update!(source_code_url: "https://github.com/example/repo-name")

      resolved = GitHubInsights::RepoResolver.resolve_project!(project)
      assert_equal "example", resolved[:owner]
      assert_equal "repo-name", resolved[:repo]
    end
  end
end
