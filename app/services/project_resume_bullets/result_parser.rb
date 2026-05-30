# frozen_string_literal: true

module ProjectResumeBullets
  class ResultParser
    VERSION = 1
    FOCUS_VALUES = %w[
      technical_depth
      product_thinking
      problem_solving
      architecture
      user_impact
      collaboration
      learning_growth
      general
    ].freeze
    MAX_BULLET_LENGTH = 500
    MAX_BULLETS = 5

    class ParseError < StandardError; end

    def self.parse(text)
      new.parse(text)
    end

    def parse(text)
      payload = extract_json(text)
      normalize(payload)
    end

    private

    def extract_json(text)
      raw = text.to_s.strip
      raise ParseError, "AI returned an empty response" if raw.blank?

      candidates = [ raw ]
      if (fenced = raw[/```(?:json)?\s*(.+?)```/m, 1])
        candidates << fenced.strip
      end
      if (object = raw[/(\{.*\})/m, 1])
        candidates << object.strip
      end

      candidates.each do |candidate|
        parsed = JSON.parse(candidate)
        return parsed if parsed.is_a?(Hash)
      rescue JSON::ParserError
        next
      end

      raise ParseError, "Could not parse AI response as structured resume bullets"
    end

    def normalize(payload)
      bullets = Array(payload["resume_bullets"]).filter_map do |bullet|
        next unless bullet.is_a?(Hash)

        text = bullet["text"].to_s.strip.slice(0, MAX_BULLET_LENGTH)
        next if text.blank?

        focus = bullet["focus"].to_s.strip
        focus = "general" unless FOCUS_VALUES.include?(focus)

        {
          "text" => text,
          "focus" => focus,
          "source_notes" => normalize_source_notes(bullet["source_notes"])
        }
      end.first(MAX_BULLETS)

      {
        "version" => payload["version"].presence || VERSION,
        "resume_bullets" => bullets,
        "missing_context_questions" => normalize_questions(payload["missing_context_questions"])
      }
    end

    def normalize_source_notes(notes)
      Array(notes).filter_map do |note|
        cleaned = note.to_s.strip
        cleaned.presence
      end
    end

    def normalize_questions(questions)
      Array(questions).filter_map do |question|
        cleaned = question.to_s.strip
        cleaned.presence
      end
    end
  end
end
