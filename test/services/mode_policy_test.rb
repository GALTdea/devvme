# frozen_string_literal: true

require "test_helper"

class ModePolicyTest < ActiveSupport::TestCase
  test "normalize falls back to profile_builder and empty hash" do
    result = ModePolicy.normalize(mode: "unknown", target_type: "bad", target_data: "nope")
    assert_equal "profile_builder", result[:mode]
    assert_nil result[:target_type]
    assert_equal({}, result[:target_data])
  end

  test "validate returns normalized payload for valid input" do
    result = ModePolicy.validate!(
      mode: "fit_gap",
      target_type: "job_description",
      target_data: { "job_description_text" => "Rails" }
    )

    assert_equal "fit_gap", result[:mode]
    assert_equal "job_description", result[:target_type]
    assert_equal({ "job_description_text" => "Rails" }, result[:target_data])
  end
end
