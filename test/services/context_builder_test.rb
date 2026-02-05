# frozen_string_literal: true

require "test_helper"

class ContextBuilderTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "context_builder@example.com",
      password: "password123",
      username: "contextbuilder",
      full_name: "Context Builder User",
      bio: "Builder bio",
      skills: ["Ruby"]
    )
    @user.update!(account_status: :active, github_url: "https://github.com/contextbuilder")
  end

  test "build for profile_builder includes user profile keys" do
    context = ContextBuilder.build(
      user: @user,
      mode: "profile_builder",
      pasted_content: "extra notes",
      github_data: { "profile" => { "login" => "contextbuilder" } },
      target_data: {}
    )

    assert context.key?("user_profile")
    assert_equal "Context Builder User", context["user_profile"][:full_name]
    assert_equal "extra notes", context["pasted_content"]
  end

  test "build for fit_gap includes target_data" do
    context = ContextBuilder.build(
      user: @user,
      mode: "fit_gap",
      pasted_content: nil,
      github_data: {},
      target_data: { "job_description_text" => "Need Rails" }
    )

    assert_equal({ "job_description_text" => "Need Rails" }, context["target_data"])
  end
end
