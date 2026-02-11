# frozen_string_literal: true

module GitHubInsights
  class SyncService
    VALID_SYNC_TYPES = %w[light deep].freeze
    VALID_SOURCES = %w[auto manual].freeze
    MAX_ERROR_LENGTH = 500

    class SyncError < StandardError; end
    class RetryableSyncError < SyncError; end
    class PermanentSyncError < SyncError; end

    def self.call(project:, sync_type: "light", source: "auto")
      new.call(project:, sync_type:, source:)
    end

    def initialize(repo_resolver: RepoResolver, fetch_service: FetchService, compute_service: ComputeService)
      @repo_resolver = repo_resolver
      @fetch_service = fetch_service
      @compute_service = compute_service
    end

    def call(project:, sync_type: "light", source: "auto")
      validate_inputs!(sync_type, source)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      queue_wait_seconds = nil

      project.with_lock do
        return { "status" => "skipped", "reason" => "sync_in_progress" } if project.github_insights_sync_status == "syncing"

        queue_wait_seconds = queue_wait_seconds_for(project)
        project.update!(github_insights_sync_status: "syncing", github_insights_last_error: nil)
      end

      repo_identity = @repo_resolver.resolve_project!(project)
      raw_payload = fetch_payload(
        repo_identity: repo_identity,
        sync_type: sync_type,
        oauth_token: project.user&.github_oauth_token_for_insights
      )
      computed = @compute_service.call(
        project: project,
        repo_identity: repo_identity,
        raw_payload: raw_payload
      )

      snapshot = ProjectGitHubInsightSnapshot.create!(
        project: project,
        sync_type: sync_type,
        source: source,
        captured_at: Time.current,
        repo_payload: raw_payload,
        metrics_payload: computed["metrics"] || {},
        highlights_payload: { "highlights" => computed["highlights"] || [], "caveats" => computed["caveats"] || [] },
        errors_payload: {},
        duration_ms: duration_ms_since(started_at)
      )

      project.update!(
        github_insights_sync_status: "ready",
        github_insights_last_synced_at: Time.current,
        github_insights_last_error: nil,
        github_insights_summary: computed["summary"] || {}
      )

      duration_ms = duration_ms_since(started_at)
      instrument_event(
        "success",
        project: project,
        sync_type: sync_type,
        source: source,
        duration_ms: duration_ms,
        queue_wait_seconds: queue_wait_seconds
      )
      Rails.logger.info(log_message(
        "success",
        project_id: project.id,
        sync_type: sync_type,
        source: source,
        duration_ms: duration_ms,
        queue_wait_seconds: queue_wait_seconds
      ))

      result = {
        "status" => "ready",
        "project_id" => project.id,
        "snapshot_id" => snapshot.id,
        "summary" => computed["summary"],
        "metrics" => computed["metrics"],
        "highlights" => computed["highlights"],
        "caveats" => computed["caveats"],
        "confidence" => computed["confidence"]
      }
      result["queue_wait_seconds"] = queue_wait_seconds if queue_wait_seconds.present?
      result
    rescue RepoResolver::InvalidRepositoryUrlError, FetchService::RepositoryNotFoundError, ArgumentError => e
      message = repository_access_message(e.message, project)
      mark_failed(project, message)
      instrument_failure(project:, sync_type:, source:, started_at:, error: e, queue_wait_seconds: queue_wait_seconds, failure_type: "permanent")
      raise PermanentSyncError, message
    rescue FetchService::GitHubRateLimitError, FetchService::TemporaryFetchError => e
      mark_failed(project, e.message)
      instrument_failure(project:, sync_type:, source:, started_at:, error: e, queue_wait_seconds: queue_wait_seconds, failure_type: "retryable")
      raise RetryableSyncError, e.message
    rescue FetchService::FetchError => e
      mark_failed(project, e.message)
      instrument_failure(project:, sync_type:, source:, started_at:, error: e, queue_wait_seconds: queue_wait_seconds, failure_type: "retryable")
      raise RetryableSyncError, e.message
    rescue StandardError => e
      mark_failed(project, e.message)
      instrument_failure(project:, sync_type:, source:, started_at:, error: e, queue_wait_seconds: queue_wait_seconds, failure_type: "retryable")
      raise RetryableSyncError, e.message
    end

    private

    def validate_inputs!(sync_type, source)
      raise ArgumentError, "Unsupported sync_type: #{sync_type}" unless VALID_SYNC_TYPES.include?(sync_type.to_s)
      raise ArgumentError, "Unsupported source: #{source}" unless VALID_SOURCES.include?(source.to_s)
    end

    def mark_failed(project, message)
      project.update_columns(
        github_insights_sync_status: "failed",
        github_insights_last_error: message.to_s.truncate(MAX_ERROR_LENGTH)
      )
    end

    def duration_ms_since(started_at)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      (elapsed * 1000).round
    end

    def queue_wait_seconds_for(project)
      return nil unless project.github_insights_sync_status == "queued"
      return nil if project.updated_at.blank?

      (Time.current - project.updated_at).round(2)
    end

    def fetch_payload(repo_identity:, sync_type:, oauth_token:)
      @fetch_service.call(
        owner: repo_identity[:owner],
        repo: repo_identity[:repo],
        sync_type: sync_type,
        oauth_token: oauth_token
      )
    rescue ArgumentError => e
      raise unless e.message.to_s.include?("unknown keyword: :oauth_token")

      @fetch_service.call(
        owner: repo_identity[:owner],
        repo: repo_identity[:repo],
        sync_type: sync_type
      )
    end

    def instrument_failure(project:, sync_type:, source:, started_at:, error:, queue_wait_seconds:, failure_type:)
      duration_ms = duration_ms_since(started_at)
      instrument_event(
        "failure",
        project: project,
        sync_type: sync_type,
        source: source,
        duration_ms: duration_ms,
        queue_wait_seconds: queue_wait_seconds,
        error_class: error.class.name,
        error_message: error.message,
        failure_type: failure_type
      )
      Rails.logger.warn(log_message(
        "failure",
        project_id: project.id,
        sync_type: sync_type,
        source: source,
        duration_ms: duration_ms,
        queue_wait_seconds: queue_wait_seconds,
        error_class: error.class.name,
        error_message: error.message,
        failure_type: failure_type
      ))
    end

    def repository_access_message(original_message, project)
      return original_message unless original_message.to_s.match?(/not found|publicly accessible/i)

      return original_message if project.user&.github_oauth_connected?

      "#{original_message} Connect GitHub OAuth from your account to analyze private repositories."
    end

    def instrument_event(result, project:, sync_type:, source:, duration_ms:, queue_wait_seconds:, error_class: nil, error_message: nil, failure_type: nil)
      payload = {
        project_id: project.id,
        result: result,
        sync_type: sync_type,
        source: source,
        duration_ms: duration_ms,
        queue_wait_seconds: queue_wait_seconds
      }.compact
      payload[:error_class] = error_class if error_class.present?
      payload[:error_message] = error_message if error_message.present?
      payload[:failure_type] = failure_type if failure_type.present?

      ActiveSupport::Notifications.instrument("github_insights.sync", payload)
    end

    def log_message(result, project_id:, sync_type:, source:, duration_ms:, queue_wait_seconds:, error_class: nil, error_message: nil, failure_type: nil)
      parts = [
        "GitHubInsights::SyncService",
        "result=#{result}",
        "project_id=#{project_id}",
        "sync_type=#{sync_type}",
        "source=#{source}",
        "duration_ms=#{duration_ms}"
      ]
      parts << "queue_wait_seconds=#{queue_wait_seconds}" if queue_wait_seconds.present?
      parts << "failure_type=#{failure_type}" if failure_type.present?
      parts << "error_class=#{error_class}" if error_class.present?
      parts << "error_message=#{error_message}" if error_message.present?
      parts.join(" ")
    end
  end
end
