# frozen_string_literal: true

# Processes the next Architect LLM reply and broadcasts the result via Turbo Stream.
# Called after the user sends a message; calls ArchitectService.reply, then optionally
# ArchitectService.finalize when the interview is complete.
# Error handling: retries on timeout/connection failures; broadcasts user-friendly
# errors to the session (error_indicator partial); finalize errors do not re-raise
# so the session stays in_progress and the user can retry.
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

    if assistant_message.present?
      broadcast_message(session, assistant_message)
      # Hide thinking indicator after showing assistant reply (session still in progress).
      broadcast_thinking_idle(session) unless interview_complete
    end

    if interview_complete
      finalize_session(session_id, session)
    end
  rescue ArchitectService::MissingApiKeysError => e
    Rails.logger.error "ArchitectReplyJob: #{e.message}"
    broadcast_error(session_id, I18n.t("architect.errors.missing_api_keys"))
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

  def broadcast_thinking_idle(session)
    Turbo::StreamsChannel.broadcast_replace_to(
      session,
      target: "architect_thinking_indicator",
      partial: "architect/sessions/thinking_idle"
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

  def finalize_session(session_id, session)
    ArchitectService.finalize(session)
    session.reload
    broadcast_session_complete(session)
  rescue ArchitectService::MissingApiKeysError => e
    Rails.logger.error "ArchitectReplyJob finalize: #{e.message}"
    broadcast_error(session_id, I18n.t("architect.errors.missing_api_keys"))
  rescue Faraday::Error => e
    Rails.logger.error "ArchitectReplyJob finalize LLM error: #{e.message}"
    broadcast_error(session_id, I18n.t("architect.errors.llm_failed"))
  rescue StandardError => e
    Rails.logger.error "ArchitectReplyJob finalize: #{e.class} #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    broadcast_error(session_id, I18n.t("architect.errors.generation_failed"))
  end

  def broadcast_error(session_id, error_message)
    session = ArchitectSession.find_by(id: session_id)
    return unless session

    html = ApplicationController.render(
      partial: "architect/sessions/error_indicator",
      locals: { message: error_message },
      formats: [:html]
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      session,
      target: "architect_thinking_indicator",
      html: html
    )
  end
end
