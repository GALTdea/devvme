# frozen_string_literal: true

module GitHubInsights
  class SyncService
    VALID_SYNC_TYPES = %w[light deep].freeze
    VALID_SOURCES = %w[auto manual].freeze
    MAX_ERROR_LENGTH = 500

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

      project.with_lock do
        return { "status" => "skipped", "reason" => "sync_in_progress" } if project.github_insights_sync_status == "syncing"

        project.update!(github_insights_sync_status: "syncing", github_insights_last_error: nil)
      end

      repo_identity = @repo_resolver.resolve_project!(project)
      raw_payload = @fetch_service.call(
        owner: repo_identity[:owner],
        repo: repo_identity[:repo],
        sync_type: sync_type
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
        duration_ms: nil
      )

      project.update!(
        github_insights_sync_status: "ready",
        github_insights_last_synced_at: Time.current,
        github_insights_last_error: nil,
        github_insights_summary: computed["summary"] || {}
      )

      {
        "status" => "ready",
        "project_id" => project.id,
        "snapshot_id" => snapshot.id,
        "summary" => computed["summary"],
        "metrics" => computed["metrics"],
        "highlights" => computed["highlights"],
        "caveats" => computed["caveats"],
        "confidence" => computed["confidence"]
      }
    rescue StandardError => e
      project.update_columns(
        github_insights_sync_status: "failed",
        github_insights_last_error: e.message.to_s.truncate(MAX_ERROR_LENGTH)
      )
      raise
    end

    private

    def validate_inputs!(sync_type, source)
      raise ArgumentError, "Unsupported sync_type: #{sync_type}" unless VALID_SYNC_TYPES.include?(sync_type.to_s)
      raise ArgumentError, "Unsupported source: #{source}" unless VALID_SOURCES.include?(source.to_s)
    end
  end
end
