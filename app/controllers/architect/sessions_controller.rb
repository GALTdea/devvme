# frozen_string_literal: true

module Architect
  class SessionsController < ApplicationController
    # Rate limits: max 3 sessions per hour, max 20 messages per session
    MAX_SESSIONS_PER_HOUR = 3

    before_action :authenticate_user!
    before_action :set_session, only: [:show, :message, :accept, :destroy]
    before_action :check_create_rate_limit, only: [:create]
    before_action :check_message_rate_limit, only: [:message]

    def new
      @architect_session = current_user.architect_sessions.build(goal: "both")
      authorize @architect_session
    end

    def create
      @architect_session = current_user.architect_sessions.build
      authorize @architect_session

      permitted = params.fetch(:architect_session, {}).permit(:goal, :pasted_content)
      goal = permitted[:goal].to_s.presence
      goal = "both" unless goal.present? && ArchitectSession.goals.key?(goal)
      pasted_content = permitted[:pasted_content].to_s.strip.presence

      result = ArchitectService.start_session(current_user, goal, pasted_content: pasted_content)
      session = result[:session]

      redirect_to architect_session_path(session), notice: t("architect.sessions.created")
    rescue ArchitectService::MissingApiKeysError
      redirect_to dashboard_path, alert: t("architect.errors.missing_api_keys")
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_architect_session_path, alert: e.record&.errors&.full_messages&.to_sentence || e.message
    end

    def show
      authorize @architect_session
    end

    def message
      authorize @architect_session, :message?

      content = message_params[:content].to_s.strip
      if content.blank?
        redirect_to architect_session_path(@architect_session), alert: t("architect.errors.message_blank")
        return
      end

      next_sequence = @architect_session.architect_messages.maximum(:sequence).to_i + 1
      user_message = @architect_session.architect_messages.create!(
        role: :user,
        content: content,
        sequence: next_sequence
      )

      ArchitectReplyJob.perform_later(@architect_session.id)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("architect_messages", partial: "architect/messages/message", locals: { message: user_message }),
            turbo_stream.replace("architect_thinking_indicator", partial: "architect/sessions/thinking_indicator")
          ], status: :ok
        end
        format.html { redirect_to architect_session_path(@architect_session), notice: t("architect.sessions.message_sent") }
      end
    end

    def accept
      authorize @architect_session, :accept?

      unless @architect_session.completed?
        redirect_to architect_session_path(@architect_session), alert: t("architect.errors.not_completed")
        return
      end

      attrs = {}
      attrs[:bio] = @architect_session.generated_bio if @architect_session.goal_bio? || @architect_session.goal_both?
      attrs[:headline] = @architect_session.generated_headline if @architect_session.goal_headline? || @architect_session.goal_both?

      if current_user.update(attrs)
        if params[:edit].present?
          redirect_to edit_profile_path, notice: t("architect.sessions.accepted")
        else
          redirect_to profile_path, notice: t("architect.sessions.accepted")
        end
      else
        redirect_to architect_session_path(@architect_session), alert: current_user.errors.full_messages.to_sentence
      end
    end

    def destroy
      authorize @architect_session
      @architect_session.destroy!
      redirect_to dashboard_path, notice: t("architect.sessions.destroyed")
    end

    private

    def set_session
      @architect_session = current_user.architect_sessions.find(params[:id])
    end

    def message_params
      params.fetch(:architect_message, {}).permit(:content)
    end

    def check_create_rate_limit
      count = current_user.architect_sessions.where("created_at > ?", 1.hour.ago).count
      return if count < MAX_SESSIONS_PER_HOUR

      redirect_to dashboard_path, alert: t("architect.errors.rate_limit_sessions")
    end

    def check_message_rate_limit
      return if @architect_session.architect_messages.count < ArchitectService::MAX_QA_MESSAGES

      redirect_to architect_session_path(@architect_session), alert: t("architect.errors.rate_limit_messages")
    end
  end
end
