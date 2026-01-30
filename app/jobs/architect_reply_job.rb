# frozen_string_literal: true

# Processes the next Architect LLM reply and broadcasts the result via Turbo Stream.
# Called after the user sends a message; calls ArchitectService.reply, then optionally
# ArchitectService.finalize when the interview is complete.
class ArchitectReplyJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TimeoutError, wait: :polynomially_longer, attempts: 3
  retry_on Faraday::ConnectionFailed, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError
  discard_on ArchitectService::MissingApiKeysError

  def perform(session_id)
    session = ArchitectSession.find(session_id)
    return unless session.in_progress?

    assistant_message, interview_complete = ArchitectService.reply(session)

    broadcast_message(session, assistant_message) if assistant_message.present?

    if interview_complete
      ArchitectService.finalize(session)
      session.reload
      broadcast_session_complete(session)
    end
  rescue ArchitectService::MissingApiKeysError => e
    Rails.logger.error "ArchitectReplyJob: #{e.message}"
    broadcast_error(session_id, e.message)
    raise
  rescue Faraday::Error => e
    Rails.logger.error "ArchitectReplyJob LLM error: #{e.message}"
    broadcast_error(session_id, I18n.t("architect.errors.llm_failed"))
    raise
  rescue StandardError => e
    Rails.logger.error "ArchitectReplyJob: #{e.class} #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    broadcast_error(session_id, I18n.t("architect.errors.generic"))
    raise
  end

  private

  def broadcast_message(session, message)
    Turbo::StreamsChannel.broadcast_append_to(
      session,
      target: "architect_messages",
      partial: "architect/messages/message",
      locals: { message: message }
    )
  end

  def broadcast_session_complete(session)
    Turbo::StreamsChannel.broadcast_replace_to(
      session,
      target: "architect_thinking_indicator",
      partial: "architect/sessions/complete_marker",
      locals: { session: session }
    )
  end

  def broadcast_error(session_id, error_message)
    session = ArchitectSession.find_by(id: session_id)
    return unless session

    Turbo::StreamsChannel.broadcast_replace_to(
      session,
      target: "architect_thinking_indicator",
      html: "<div id=\"architect_thinking_indicator\" class=\"architect-error\" data-architect-error=\"true\">#{ERB::Util.html_escape(error_message)}</div>"
    )
  end
end
