# frozen_string_literal: true

class PromptStrategy
  def self.for(mode)
    case mode.to_s
    when "fit_gap"
      PromptStrategies::FitGap.new
    when "mock_interview"
      PromptStrategies::MockInterview.new
    when "outreach"
      PromptStrategies::Outreach.new
    else
      PromptStrategies::ProfileBuilder.new
    end
  end
end
