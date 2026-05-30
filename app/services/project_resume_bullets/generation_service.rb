# frozen_string_literal: true

module ProjectResumeBullets
  class GenerationService
    MODEL = "gpt-4o-mini"
    MAX_EMPHASIS_CHARS = 2000
    MAX_OUTPUT_TOKENS = 1500

    class GenerationError < StandardError; end

    def self.call(project:, user:, emphasis: nil)
      new.call(project:, user:, emphasis:)
    end

    def call(project:, user:, emphasis: nil)
      raise GenerationError, "Authentication required" if user.blank?
      raise GenerationError, "Project is required" if project.blank?

      cleaned_emphasis = emphasis.to_s.strip
      if cleaned_emphasis.length > MAX_EMPHASIS_CHARS
        raise GenerationError, "Emphasis notes are too long (max #{MAX_EMPHASIS_CHARS} characters)"
      end

      context = ProjectStoryBuilder::ContextBuilder.build(project:, rough_notes: cleaned_emphasis)
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
      Rails.logger.error("ProjectResumeBullets::GenerationService OpenAI error: #{e.message}")
      raise GenerationError, "Resume bullet generation is temporarily unavailable. Please try again."
    end

    def system_prompt
      focus_values = ResultParser::FOCUS_VALUES.join(", ")
      <<~PROMPT
        You are a resume bullet assistant for Devv.me.
        Help a developer turn real project context into concise, reusable resume bullets.

        Rules:
        - Use only supplied project metadata, project story fields, GitHub signals, repository analysis, and emphasis notes.
        - Preserve the developer's intent and voice.
        - Do not invent metrics, users, employers, credentials, revenue, performance claims, or unsupported impact.
        - Do not claim production users, scale, or business outcomes unless explicitly provided in the context.
        - If context is sparse, write conservative bullets and ask follow-up questions in missing_context_questions.
        - Generate 3 to 5 project-specific resume bullets.
        - Start each bullet with a strong action verb (Built, Designed, Implemented, Integrated, Improved, Developed, etc.).
        - Avoid first-person language such as "I built" or "I designed".
        - Keep each bullet to one sentence, or at most two short sentences.
        - Include technologies only when they strengthen the bullet.
        - If no measurable outcome is provided, describe demonstrated work or capability instead of inventing impact.
        - Do not rewrite the whole resume or generate cover letters, social posts, or recruiter summaries.
        - Do not modify or suggest changes to project story fields.

        Allowed focus values: #{focus_values}

        Return strict JSON with this shape:
        {
          "version": 1,
          "resume_bullets": [
            {
              "text": "",
              "focus": "technical_depth",
              "source_notes": []
            }
          ],
          "missing_context_questions": []
        }
      PROMPT
    end

    def user_prompt(context)
      <<~PROMPT
        Generate project-specific resume bullets from this context JSON:
        #{context.to_json}
      PROMPT
    end
  end
end
