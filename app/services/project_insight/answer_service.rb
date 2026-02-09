# frozen_string_literal: true

module ProjectInsight
  class AnswerService
    MODEL = "gpt-4o-mini"
    MAX_QUESTION_CHARS = 400
    MAX_OUTPUT_TOKENS = 400

    class AnswerError < StandardError; end

    def self.call(project:, question:, user:)
      new.call(project:, question:, user:)
    end

    def call(project:, question:, user:)
      raise AnswerError, "Authentication required" if user.blank?
      raise AnswerError, "Project Insight is not enabled for this project" unless project.project_insight_ready?

      cleaned_question = question.to_s.strip
      raise AnswerError, "Question cannot be blank" if cleaned_question.blank?
      raise AnswerError, "Question is too long (max #{MAX_QUESTION_CHARS} characters)" if cleaned_question.length > MAX_QUESTION_CHARS

      analysis = fetch_analysis!(project)
      raise AnswerError, "Project analysis is not available yet" if analysis.blank?

      text = call_openai(project: project, question: cleaned_question, analysis: analysis)
      answer, bullets = parse_response(text)

      {
        "answer" => answer,
        "evidence" => bullets,
        "question" => cleaned_question,
        "model" => MODEL
      }
    end

    private

    def fetch_analysis!(project)
      AnalysisService.fetch(project)
    rescue ProjectInsight::AnalysisService::RepositoryNotFoundError
      raise AnswerError, "Repository could not be accessed. Verify this project's Source Code URL points to a public GitHub repository."
    rescue ProjectInsight::AnalysisService::GitHubRateLimitError
      raise AnswerError, "GitHub rate limit reached while analyzing this project. Please try again in a few minutes."
    rescue ProjectInsight::AnalysisService::AnalysisError
      raise AnswerError, "Project analysis is temporarily unavailable. Please try again."
    end

    def call_openai(project:, question:, analysis:)
      api_key = ArchitectService.openai_api_key
      raise ArchitectService::MissingApiKeysError, "OpenAI API key not set" if api_key.blank?

      client = OpenAI::Client.new(access_token: api_key)

      response = client.chat(
        parameters: {
          model: MODEL,
          temperature: 0.2,
          max_tokens: MAX_OUTPUT_TOKENS,
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_prompt(project: project, question: question, analysis: analysis) }
          ]
        }
      )

      response.is_a?(Hash) ? response.dig("choices", 0, "message", "content").to_s : response.choices.first.message.content.to_s
    end

    def system_prompt
      <<~PROMPT
        You are Project Insight for Devv.me.
        Answer recruiter-style technical questions with concise, honest, evidence-based language.

        Rules:
        - Use only the supplied repository analysis.
        - If evidence is insufficient, explicitly say what is unknown.
        - Keep answer concise (max 6 sentences).
        - Mention 2-4 evidence bullets.
        - Never claim certainty without evidence.

        Output format:
        ANSWER: <short answer>
        EVIDENCE:
        - <bullet>
        - <bullet>
      PROMPT
    end

    def user_prompt(project:, question:, analysis:)
      <<~PROMPT
        Project title: #{project.title}
        Question: #{question}

        Repository analysis JSON:
        #{analysis.to_json}
      PROMPT
    end

    def parse_response(text)
      return ["No answer generated.", []] if text.blank?

      answer = text[/\A\s*ANSWER:\s*(.+?)(?:\nEVIDENCE:|\z)/mi, 1].to_s.strip
      answer = text.strip if answer.blank?

      evidence_section = text[/\nEVIDENCE:\s*(.+)\z/mi, 1].to_s
      bullets = evidence_section.lines.map(&:strip).select { |line| line.start_with?("-") }.map { |line| line.sub(/\A-\s*/, "") }

      [answer, bullets.first(4)]
    end
  end
end
