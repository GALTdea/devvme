# frozen_string_literal: true

class GitHubInsightsStaleRefreshJob < ApplicationJob
  queue_as :default

  STALE_AFTER = 7.days
  BATCH_SIZE = 100

  def perform
    queued_count = 0
    scanned_count = 0

    stale_candidates.find_each(batch_size: BATCH_SIZE) do |project|
      scanned_count += 1
      next unless should_refresh?(project)

      sync_type = project.github_insights_sync_status.in?(%w[never failed]) ? "deep" : "light"
      GitHubInsightsSyncJob.perform_later(project.id, sync_type: sync_type, source: "auto")
      queued_count += 1
    end

    ActiveSupport::Notifications.instrument(
      "github_insights.stale_refresh",
      scanned_count: scanned_count,
      queued_count: queued_count
    )
    Rails.logger.info("GitHubInsightsStaleRefreshJob scanned=#{scanned_count} queued=#{queued_count}")
  end

  private

  def stale_candidates
    Project.where(github_insights_enabled: true)
           .where("(source_code_url IS NOT NULL AND source_code_url <> '') OR (github_url IS NOT NULL AND github_url <> '')")
  end

  def should_refresh?(project)
    return false if project.github_insights_sync_status.in?(%w[queued syncing])
    return false if project.project_github_repo_url.blank?

    project.github_insights_stale?(stale_after: STALE_AFTER)
  end
end
