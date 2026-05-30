# frozen_string_literal: true

module ProjectStoryBuilder
  class GenerationService
    MODEL = "gpt-4o-mini"
    MAX_ROUGH_NOTES_CHARS = 2000
    MAX_OUTPUT_TOKENS = 2500

    class GenerationError < StandardError; end

    def self.call(project:, user:, rough_notes: nil)
      new.call(project:, user:, rough_notes:)
    end

    def call(project:, user:, rough_notes: nil)
      raise GenerationError, "Authentication required" if user.blank?
      raise GenerationError, "Project is required" if project.blank?

      cleaned_notes = rough_notes.to_s.strip
      if cleaned_notes.length > MAX_ROUGH_NOTES_CHARS
        raise GenerationError, "Rough notes are too long (max #{MAX_ROUGH_NOTES_CHARS} characters)"
      end

      context = ContextBuilder.build(project:, rough_notes: cleaned_notes)
      text = call_openai(context)
      ResultParser.parse(text)
    end

    private

    def call_openai(context)
      api_key = ArchitectService.openai_api_key
      raise ArchitectService::MissingApiKeysError, "OpenAI API key not set. Add it to credentials or set ENV OPENAI_API_KEY." if api_key.blank?

      client = OpenAI::Client.new(access_token: api_key)
      response = client.chat(
        parameters: {
          model: MODEL,
          temperature: 0.3,
          max_tokens: MAX_OUTPUT_TOKENS,
          response_format: { type: "json_object" },
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_prompt(context) }
          ]
        }
      )

      response.is_a?(Hash) ? response.dig("choices", 0, "message", "content").to_s : response.choices.first.message.content.to_s
    rescue ResultParser::ParseError, ArchitectService::MissingApiKeysError
      raise
    rescue StandardError => e
      Rails.logger.error("ProjectStoryBuilder::GenerationService OpenAI error: #{e.message}")
      raise GenerationError, "Story generation is temporarily unavailable. Please try again."
    end

    def system_prompt
      field_list = ProjectStory::PUBLIC_STORY_FIELDS.join(", ")
      <<~PROMPT
        You are Project Story Builder for Devv.me.
        Help a developer turn real project context into clearer proof-of-work story fields.

        Rules:
        - Use only supplied project metadata, existing story fields, GitHub signals, repository analysis, and rough notes.
        - Preserve the developer's voice and intent.
        - Do not invent metrics, users, employers, credentials, impact, or outcomes.
        - If context is sparse, write conservative content and ask follow-up questions.
        - Distinguish GitHub-derived observations from user-provided claims.
        - Do not generate resume bullets, social posts, recruiter summaries, or promotional copy.
        - Only target these story fields: #{field_list}
        - Leave a field blank in "fields" when there is not enough evidence to write it responsibly.

        Return strict JSON with this shape:
        {
          "version": 1,
          "fields": {
            "overview": "",
            "problem": "",
            "intended_users": "",
            "why_built": "",
            "role": "",
            "technical_decisions": "",
            "hardest_challenge": "",
            "lessons_learned": "",
            "demonstrates": ""
          },
          "evidence_notes": [
            { "source": "project_metadata|github_signals|repository_analysis|rough_notes", "summary": "" }
          ],
          "missing_context_questions": []
        }
      PROMPT
    end

    def user_prompt(context)
      <<~PROMPT
        Generate project story suggestions from this context JSON:
        #{context.to_json}
      PROMPT
    end
  end
end
