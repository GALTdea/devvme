# frozen_string_literal: true

require "test_helper"
require_relative "../../app/services/github_context_service"

class GitHubContextServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "github_ctx@example.com",
      password: "password123",
      username: "githubctx",
      full_name: "GitHub Context User"
    )
    @user.update!(account_status: :active)
  end

  test "fetch_for_user returns nil when user has no github_url" do
    assert_nil ::GitHubContextService.fetch_for_user(@user)
  end

  test "fetch_for_user returns nil when github_url is blank string" do
    @user.update_column(:github_url, "")
    assert_nil ::GitHubContextService.fetch_for_user(@user)
  end

  test "extract_username parses github.com URL" do
    assert_equal "johndoe", ::GitHubContextService.extract_username("https://github.com/johndoe")
    assert_equal "johndoe", ::GitHubContextService.extract_username("https://github.com/johndoe/")
    assert_equal "johndoe", ::GitHubContextService.extract_username("github.com/johndoe")
  end

  test "extract_username returns nil for non-github URL" do
    assert_nil ::GitHubContextService.extract_username("https://gitlab.com/johndoe")
    assert_nil ::GitHubContextService.extract_username(nil)
    assert_nil ::GitHubContextService.extract_username("")
  end

  test "fetch_for_user returns profile and repos when API is stubbed" do
    @user.update!(github_url: "https://github.com/johndoe")
    instance = build_stubbed_service_instance
    result = instance.fetch_for_user(@user)
    assert result.is_a?(Hash)
    assert_equal "johndoe", result["profile"]["login"]
    assert_equal "Ruby dev", result["profile"]["bio"]
    assert result["repos"].is_a?(Array)
    assert_equal 1, result["repos"].size
    assert_equal "my-app", result["repos"].first["name"]
    assert result["skills_profile"].is_a?(Hash)
    assert_includes result["skills_profile"]["combined"], "Ruby"
    assert_includes result["skills_profile"]["combined"], "Ruby on Rails"
  end

  private

  def build_stubbed_service_instance
    # Subclass that overrides #get to avoid real API calls (profile, repos list, readme)
    stub_body = lambda do |path, _params = {}|
      if path.end_with?("/readme")
        { "content" => Base64.strict_encode64("# My App\nRails project.") }
      elsif path.include?("/users/") && path.include?("/repos") && !path.include?("readme")
        [{ "name" => "my-app", "description" => "A Rails app", "language" => "Ruby", "stargazers_count" => 0, "html_url" => "https://github.com/johndoe/my-app" }]
      elsif path.include?("/users/")
        { "login" => "johndoe", "name" => "John", "bio" => "Ruby dev", "public_repos" => 5 }
      else
        {}
      end
    end
    stubbed_class = Class.new(::GitHubContextService) do
      define_method(:get) { |path, params = {}| stub_body.call(path, params) }
    end
    stubbed_class.new
  end
end
