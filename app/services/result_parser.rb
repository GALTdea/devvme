# frozen_string_literal: true

class ResultParser
  def self.for(mode)
    case mode.to_s
    when "fit_gap"
      ResultParsers::FitGap.new
    when "mock_interview"
      ResultParsers::MockInterview.new
    when "outreach"
      ResultParsers::Outreach.new
    else
      ResultParsers::ProfileBuilder.new
    end
  end
end
