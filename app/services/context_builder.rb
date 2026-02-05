# frozen_string_literal: true

class ContextBuilder
  def self.build(user:, mode:, pasted_content: nil, github_data: nil, target_data: {})
    builder_for(mode).build(
      user: user,
      pasted_content: pasted_content,
      github_data: github_data,
      target_data: target_data
    )
  end

  def self.builder_for(mode)
    case mode.to_s
    when "fit_gap"
      ContextBuilders::FitGap.new
    when "mock_interview"
      ContextBuilders::MockInterview.new
    when "outreach"
      ContextBuilders::Outreach.new
    else
      ContextBuilders::ProfileBuilder.new
    end
  end
end
