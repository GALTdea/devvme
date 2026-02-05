# frozen_string_literal: true

module ResultParsers
  class ProfileBuilder
    def parse_finalize(text:, session:)
      bio = nil
      headline = nil

      if session.goal_both?
        if text =~ /\A\s*BIO:\s*\n?(.*?)(?=\n\s*HEADLINE:|\z)/im
          bio = Regexp.last_match(1).strip
        end
        if text =~ /HEADLINE:\s*\n?(.*)/im
          headline = Regexp.last_match(1).strip
        end
        bio ||= text.split(/\n\n+/).first&.strip
        headline ||= text.split(/\n\n+/).second&.strip
      elsif session.goal_bio?
        bio = text.strip
      else
        headline = text.strip
      end

      [bio, headline]
    end
  end
end
