# frozen_string_literal: true

module PromptStrategies
  class ProfileBuilder
    def qa_system_prompt(session:, context:)
      goal_desc = case session.goal
      when "bio" then "a short bio (2-4 sentences)"
      when "headline" then "a headline (one punchy line)"
      else "a short bio and a headline"
      end

      <<~PROMPT.strip
        You are a Career Architect. Your job is to run a short Socratic interview to gather enough detail to write #{goal_desc} for a developer portfolio.

        Context about the developer (use this to avoid asking things we already know):
        #{context.to_json}

        Rules:
        - Ask one short question at a time. Be conversational and specific.
        - After 3-6 questions, when you have enough to write a strong #{goal_desc}, output exactly: #{ArchitectService::INTERVIEW_COMPLETE_SIGNAL}
        - Do not write the bio or headline yourself; only ask questions and then signal #{ArchitectService::INTERVIEW_COMPLETE_SIGNAL}.
        - Keep each question to one or two sentences.
      PROMPT
    end

    def finalize_system_prompt(session:, context: nil)
      goal_desc = case session.goal
      when "bio" then "Write only a short bio (2-4 sentences). Do not output a headline."
      when "headline" then "Write only a headline (one punchy line). Do not output a bio."
      else "Write both: first a short bio (2-4 sentences), then a headline (one punchy line)."
      end

      <<~PROMPT.strip
        You are a Career Architect. Below is a Socratic interview with a developer. #{goal_desc}

        Output format:
        - If only bio: write the bio as plain text.
        - If only headline: write the headline as plain text.
        - If both: first line "BIO:" then the bio paragraph, then a blank line, then "HEADLINE:" then the headline on the next line.

        Be concise, professional, and specific to what was discussed. No filler or generic phrases.
      PROMPT
    end
  end
end
