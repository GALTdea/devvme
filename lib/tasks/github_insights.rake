# frozen_string_literal: true

namespace :github_insights do
  desc "Print rollout health metrics for GitHub enrichment"
  task rollout_report: :environment do
    window_days = ENV.fetch("WINDOW_DAYS", "7").to_i
    since = window_days.days.ago

    eligible = Project.where(github_insights_enabled: true)
                      .where("(source_code_url IS NOT NULL AND source_code_url <> '') OR (github_url IS NOT NULL AND github_url <> '')")

    total_eligible = eligible.count
    ready_count = eligible.where(github_insights_sync_status: "ready").count
    failed_count = eligible.where(github_insights_sync_status: "failed").count
    queued_count = eligible.where(github_insights_sync_status: "queued").count
    syncing_count = eligible.where(github_insights_sync_status: "syncing").count

    snapshots = ProjectGitHubInsightSnapshot.where("captured_at >= ?", since)
    snapshot_count = snapshots.count
    durations = snapshots.where.not(duration_ms: nil).pluck(:duration_ms).sort
    median_duration = percentile(durations, 50)
    p95_duration = percentile(durations, 95)

    success_rate = if total_eligible.positive?
      ((ready_count.to_f / total_eligible) * 100).round(2)
    else
      0.0
    end

    top_failures = eligible.where(github_insights_sync_status: "failed")
                           .where.not(github_insights_last_error: [nil, ""])
                           .group(:github_insights_last_error)
                           .order(Arel.sql("count_all DESC"))
                           .limit(5)
                           .count

    puts "GitHub Enrichment Rollout Report (last #{window_days} days)"
    puts "rollout_mode: #{FeatureFlags.github_project_enrichment_rollout}"
    puts "eligible_projects: #{total_eligible}"
    puts "ready: #{ready_count}"
    puts "failed: #{failed_count}"
    puts "queued: #{queued_count}"
    puts "syncing: #{syncing_count}"
    puts "success_rate_percent: #{success_rate}"
    puts "snapshots_in_window: #{snapshot_count}"
    puts "median_sync_duration_ms: #{median_duration || 'n/a'}"
    puts "p95_sync_duration_ms: #{p95_duration || 'n/a'}"
    puts "queue_to_ready_latency: tracked via github_insights.sync notification payload (queue_wait_seconds)"

    if top_failures.any?
      puts "top_failure_reasons:"
      top_failures.each do |message, count|
        puts "- #{count}x #{message}"
      end
    else
      puts "top_failure_reasons: none"
    end
  end

  def percentile(sorted_values, percentile_value)
    return nil if sorted_values.blank?

    rank = ((percentile_value / 100.0) * (sorted_values.length - 1)).round
    sorted_values[rank]
  end
end
