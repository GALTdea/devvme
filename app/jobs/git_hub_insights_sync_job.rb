# frozen_string_literal: true

class GitHubInsightsSyncJob < ApplicationJob
  queue_as :default

  retry_on GitHubInsights::SyncService::RetryableSyncError, wait: :polynomially_longer, attempts: 5
  discard_on GitHubInsights::SyncService::PermanentSyncError
  discard_on ActiveJob::DeserializationError

  def perform(project_id, sync_type: "light", source: "auto")
    project = Project.find_by(id: project_id)
    return if project.blank?
    return unless FeatureFlags.github_project_enrichment_enabled_for_project?(project)

    GitHubInsights::SyncService.call(
      project: project,
      sync_type: sync_type,
      source: source
    )
  end
end
