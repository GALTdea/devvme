# frozen_string_literal: true

module ProjectStoryBuilder
  class ResultParser
    VERSION = 1
    TARGET_FIELDS = ProjectStory::PUBLIC_STORY_FIELDS.freeze

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

      candidates = [raw]
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

      raise ParseError, "Could not parse AI response as structured story suggestions"
    end

    def normalize(payload)
      fields_source = payload["fields"].is_a?(Hash) ? payload["fields"] : payload

      fields = TARGET_FIELDS.index_with do |field|
        fields_source[field].to_s.strip.slice(0, ProjectStory::STORY_FIELD_MAX_LENGTH)
      end

      {
        "version" => payload["version"].presence || VERSION,
        "fields" => fields,
        "evidence_notes" => normalize_evidence_notes(payload["evidence_notes"]),
        "missing_context_questions" => normalize_questions(payload["missing_context_questions"])
      }
    end

    def normalize_evidence_notes(notes)
      Array(notes).filter_map do |note|
        next unless note.is_a?(Hash)

        source = note["source"].to_s.strip
        summary = note["summary"].to_s.strip
        next if source.blank? && summary.blank?

        { "source" => source, "summary" => summary }
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
