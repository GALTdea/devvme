# frozen_string_literal: true

require "test_helper"

class GitHubProfileEnrichmentServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "github_enrich@example.com",
      password: "password123",
      username: "githubenrich",
      full_name: "",
      bio: "",
      location: "",
      website_url: "",
      skills: ["Ruby"]
    )
    @user.update!(account_status: :active)
  end

  test "enrich_user merges inferred skills and fills blank profile fields" do
    github_data = {
      "profile" => {
        "name" => "Jane Dev",
        "bio" => "Backend engineer focused on APIs.",
        "location" => "Austin, TX",
        "blog" => "janedev.dev"
      },
      "repos" => [
        { "language" => "Ruby" },
        { "language" => "TypeScript" }
      ],
      "readmes" => {
        "api-service" => "Built with Ruby on Rails, PostgreSQL, and Docker."
      }
    }

    assert GitHubProfileEnrichmentService.enrich_user!(@user, github_data)
    @user.reload

    assert_equal "Jane Dev", @user.full_name
    assert_equal "Backend engineer focused on APIs.", @user.bio
    assert_equal "Austin, TX", @user.location
    assert_equal "https://janedev.dev", @user.website_url
    assert_includes @user.skills, "Ruby"
    assert_includes @user.skills, "TypeScript"
    assert_includes @user.skills, "Ruby on Rails"
    assert_includes @user.skills, "PostgreSQL"
    assert_includes @user.skills, "Docker"
  end

  test "enrich_user does not overwrite non-blank fields" do
    @user.update!(
      full_name: "Existing Name",
      bio: "Existing bio",
      location: "Existing location",
      website_url: "https://existing.dev"
    )

    github_data = {
      "profile" => {
        "name" => "Different Name",
        "bio" => "Different bio",
        "location" => "Different location",
        "blog" => "different.dev"
      },
      "repos" => [],
      "readmes" => {}
    }

    GitHubProfileEnrichmentService.enrich_user!(@user, github_data)
    @user.reload

    assert_equal "Existing Name", @user.full_name
    assert_equal "Existing bio", @user.bio
    assert_equal "Existing location", @user.location
    assert_equal "https://existing.dev", @user.website_url
  end
end
