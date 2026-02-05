# frozen_string_literal: true

require "test_helper"

class PromptStrategyTest < ActiveSupport::TestCase
  def setup
    user = User.create!(
      email: "prompt_strategy@example.com",
      password: "password123",
      username: "promptstrategy"
    )
    user.update!(account_status: :active)
    @session = ArchitectSession.create!(
      user: user,
      goal: "both",
      mode: "profile_builder",
      status: :in_progress,
      context_snapshot: { "user_profile" => { "full_name" => "Prompt User" } }
    )
  end

  test "for returns profile_builder strategy by default" do
    strategy = PromptStrategy.for("unknown_mode")
    assert_instance_of PromptStrategies::ProfileBuilder, strategy
  end

  test "qa_system_prompt includes completion signal" do
    strategy = PromptStrategy.for("profile_builder")
    prompt = strategy.qa_system_prompt(session: @session, context: @session.context_snapshot)
    assert_includes prompt, ArchitectService::INTERVIEW_COMPLETE_SIGNAL
  end
end
