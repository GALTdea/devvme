# frozen_string_literal: true

require "test_helper"

class GitHubSkillsProfileBuilderTest < ActiveSupport::TestCase
  test "build returns normalized language, topic, and README signals" do
    data = {
      "repos" => [
        { "language" => "Ruby", "topics" => ["ruby-on-rails", "api"] },
        { "language" => "TypeScript", "topics" => ["node_js", "backend"] }
      ],
      "readmes" => {
        "api-service" => "Built with Ruby on Rails, PostgreSQL, and Docker."
      }
    }

    profile = GitHubSkillsProfileBuilder.build(data)

    assert_includes profile["languages"], "Ruby"
    assert_includes profile["languages"], "TypeScript"
    assert_includes profile["topics"], "Ruby On Rails"
    assert_includes profile["topics"], "Node Js"
    assert_includes profile["readme_signals"], "Ruby on Rails"
    assert_includes profile["readme_signals"], "PostgreSQL"
    assert_includes profile["readme_signals"], "Docker"
    assert_includes profile["combined"], "Ruby"
    assert_includes profile["combined"], "Ruby On Rails"
  end
end
