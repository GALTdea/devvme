# frozen_string_literal: true

# Career Architect: AI-powered Socratic interview to generate bio/headline.
# Uses OpenAI gpt-4o-mini for Q&A and Anthropic claude-3-5-sonnet for final generation.
class ArchitectService
  OPENAI_QA_MODEL = "gpt-4o-mini"
  ANTHROPIC_GENERATION_MODEL = "claude-3-5-sonnet-20241022"
  INTERVIEW_COMPLETE_SIGNAL = "INTERVIEW_COMPLETE"
  MAX_QA_MESSAGES = 20
  MAX_FINALIZE_TOKENS = 1024

  class MissingApiKeysError < StandardError; end

  def self.start_session(user, goal, pasted_content: nil)
    new.start_session(user, goal, pasted_content: pasted_content)
  end

  def self.reply(session)
    new.reply(session)
  end

  def self.finalize(session)
    new.finalize(session)
  end

  def self.build_context(user, pasted_content = nil)
    new.build_context(user, pasted_content)
  end

  # ENV overrides credentials so export OPENAI_API_KEY wins when testing.
  def self.openai_api_key
    (ENV["OPENAI_API_KEY"].to_s.strip.presence || Rails.application.credentials.dig(:openai, :api_key).to_s.strip.presence).presence
  end

  def self.anthropic_api_key
    (ENV["ANTHROPIC_API_KEY"].to_s.strip.presence || Rails.application.credentials.dig(:anthropic, :api_key).to_s.strip.presence).presence
  end

  def self.openai_configured?
    openai_api_key.present?
  end

  def self.anthropic_configured?
    anthropic_api_key.present?
  end

  def start_session(user, goal, pasted_content: nil)
    ensure_openai_configured!
    context = build_context(user, pasted_content)
    session = ArchitectSession.create!(
      user: user,
      goal: goal.to_s,
      status: :in_progress,
      context_snapshot: context
    )
    # First assistant message: greeting + first question (via reply so we have one message flow)
    _message, interview_complete = reply(session)
    session.reload
    { session: session, interview_complete: interview_complete }
  end

  def reply(session)
    session.reload
    raise ArgumentError, "session must be in_progress" unless session.in_progress?

    messages = session.architect_messages.ordered.map do |m|
      { role: m.role, content: m.content }
    end
    # First turn: no user message yet; prompt the model to ask the first question
    messages = [{ role: "user", content: "Begin the Socratic interview. Ask your first question." }] if messages.empty?

    if session.architect_messages.count >= MAX_QA_MESSAGES
      # Cap: treat as complete and finalize
      return [nil, true]
    end

    system_prompt = qa_system_prompt(session)
    response_text = call_openai(system_prompt, messages)
    return [nil, true] if response_text.blank?

    interview_complete = response_text.include?(INTERVIEW_COMPLETE_SIGNAL)
    display_text = response_text.gsub(INTERVIEW_COMPLETE_SIGNAL, "").strip.presence
    display_text = "I have enough information to craft your profile. One moment…" if interview_complete && display_text.blank?

    next_sequence = (session.architect_messages.maximum(:sequence) || -1) + 1
    assistant_message = session.architect_messages.create!(
      role: :assistant,
      content: display_text.presence || "Interview complete.",
      sequence: next_sequence
    )
    session.increment!(:question_count) if response_text.match?(/\?\s*\z/)

    [assistant_message, interview_complete]
  end

  def finalize(session)
    session.reload
    raise ArgumentError, "session must be in_progress" unless session.in_progress?

    conversation = session.architect_messages.ordered.map do |m|
      "#{m.role.capitalize}: #{m.content}"
    end.join("\n\n")

    system_prompt = finalize_system_prompt(session)
    response_text = call_anthropic(system_prompt, conversation)
    return false if response_text.blank?

    bio, headline = parse_finalize_response(response_text, session)
    session.update!(
      generated_bio: bio.presence&.strip,
      generated_headline: headline.presence&.strip,
      status: :completed
    )
    true
  end

  def build_context(user, pasted_content = nil)
    user_profile = {
      full_name: user.full_name,
      job_title: user.job_title,
      location: user.location,
      skills: user.skills.is_a?(Array) ? user.skills : [],
      github_url: user.github_url,
      linkedin_url: user.linkedin_url,
      bio: user.bio,
      headline: user.headline
    }.compact

    projects = user.projects.published.by_display_order.limit(20).map do |p|
      {
        title: p.title,
        description: p.description,
        technologies_used: p.technologies_used.is_a?(Array) ? p.technologies_used : []
      }
    end

    github = GitHubContextService.fetch_for_user(user)

    {
      "user_profile" => user_profile,
      "projects" => projects,
      "github" => github,
      "pasted_content" => pasted_content.to_s.strip.presence
    }.compact
  end

  private

  def qa_system_prompt(session)
    goal_desc = case session.goal
    when "bio" then "a short bio (2–4 sentences)"
    when "headline" then "a headline (one punchy line)"
    else "a short bio and a headline"
    end

    context_json = session.context_snapshot.to_json
    <<~PROMPT.strip
      You are a Career Architect. Your job is to run a short Socratic interview to gather enough detail to write #{goal_desc} for a developer portfolio.

      Context about the developer (use this to avoid asking things we already know):
      #{context_json}

      Rules:
      - Ask one short question at a time. Be conversational and specific.
      - After 3–6 questions, when you have enough to write a strong #{goal_desc}, output exactly: #{INTERVIEW_COMPLETE_SIGNAL}
      - Do not write the bio or headline yourself; only ask questions and then signal #{INTERVIEW_COMPLETE_SIGNAL}.
      - Keep each question to one or two sentences.
    PROMPT
  end

  def finalize_system_prompt(session)
    goal_desc = case session.goal
    when "bio" then "Write only a short bio (2–4 sentences). Do not output a headline."
    when "headline" then "Write only a headline (one punchy line). Do not output a bio."
    else "Write both: first a short bio (2–4 sentences), then a headline (one punchy line)."
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

  def parse_finalize_response(text, session)
    bio = nil
    headline = nil

    if session.goal_both?
      if text =~ /\A\s*BIO:\s*\n?(.*?)(?=\n\s*HEADLINE:|\z)/im
        bio = Regexp.last_match(1).strip
      end
      if text =~ /HEADLINE:\s*\n?(.*)/im
        headline = Regexp.last_match(1).strip
      end
      # Fallback: first paragraph = bio, second = headline
      bio ||= text.split(/\n\n+/).first&.strip
      headline ||= text.split(/\n\n+/).second&.strip
    elsif session.goal_bio?
      bio = text.strip
    else
      headline = text.strip
    end

    [bio, headline]
  end

  def ensure_openai_configured!
    raise MissingApiKeysError, "OpenAI API key not set. Add it to credentials (openai.api_key) or set ENV OPENAI_API_KEY." if self.class.openai_api_key.blank?
  end

  def call_openai(system_prompt, messages)
    api_key = self.class.openai_api_key
    raise MissingApiKeysError, "OpenAI API key not set (credentials or OPENAI_API_KEY)" if api_key.blank?

    # Debug: log key source so we can see if Rails is using ENV or credentials (401 often = wrong key from credentials)
    from_env = ENV["OPENAI_API_KEY"].to_s.strip.presence
    source = from_env.present? && api_key == from_env ? "ENV" : "credentials"
    Rails.logger.info "ArchitectService OpenAI key source: #{source}, length: #{api_key.length}"

    client = OpenAI::Client.new(access_token: api_key)
    api_messages = [{ role: "system", content: system_prompt }] + messages.map { |m| m.transform_keys(&:to_s) }

    response = client.chat(
      parameters: {
        model: OPENAI_QA_MODEL,
        messages: api_messages,
        max_tokens: 512,
        temperature: 0.7
      }
    )

    content = response.is_a?(Hash) ? response.dig("choices", 0, "message", "content") : response.choices&.first&.message&.content
    content.to_s
  rescue Faraday::UnauthorizedError => e
    Rails.logger.error "ArchitectService OpenAI 401: #{e.message}"
    raise MissingApiKeysError, "OpenAI API key is invalid or expired. Check your key at https://platform.openai.com/api-keys (no extra spaces when pasting)."
  rescue Faraday::Error => e
    Rails.logger.error "ArchitectService OpenAI error: #{e.message}"
    raise
  end

  def call_anthropic(system_prompt, user_content)
    api_key = self.class.anthropic_api_key
    raise MissingApiKeysError, "Anthropic API key not set (credentials or ANTHROPIC_API_KEY)" if api_key.blank?

    client = Anthropic::Client.new(api_key: api_key)
    response = client.messages.create(
      model: ANTHROPIC_GENERATION_MODEL,
      system_: system_prompt,
      messages: [{ role: "user", content: user_content }],
      max_tokens: MAX_FINALIZE_TOKENS,
      temperature: 0.4
    )

    extract_anthropic_text(response)
  rescue Faraday::UnauthorizedError => e
    Rails.logger.error "ArchitectService Anthropic 401: #{e.message}"
    raise MissingApiKeysError, "Anthropic API key is invalid or expired. Check your key at https://console.anthropic.com/ (no extra spaces when pasting)."
  rescue Faraday::Error => e
    Rails.logger.error "ArchitectService Anthropic error: #{e.message}"
    raise
  end

  def extract_anthropic_text(message)
    return "" unless message.respond_to?(:content) && message.content.is_a?(Array)

    message.content.filter_map do |block|
      block.respond_to?(:text) ? block.text : nil
    end.join
  end
end
