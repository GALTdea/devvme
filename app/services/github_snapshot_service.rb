# frozen_string_literal: true

# Stores a stable GitHub profile snapshot per user to avoid refetching on every analysis.
class GitHubSnapshotService
  SNAPSHOT_TTL = 24.hours

  def self.fetch_for_user(user, force_refresh: false)
    new.fetch_for_user(user, force_refresh: force_refresh)
  end

  def fetch_for_user(user, force_refresh: false)
    return nil if user.github_url.blank?

    username = GitHubContextService.extract_username(user.github_url)
    return nil if username.blank?

    snapshot = user.github_profile_snapshot
    if snapshot.present? && !force_refresh && !stale?(snapshot)
      return snapshot.payload.presence || {}
    end

    data = GitHubContextService.fetch_for_username(username, force_refresh: true)
    return snapshot.payload.presence if data.blank? && snapshot.present?
    return nil if data.blank?

    payload = data.presence || {}
    upsert_snapshot(user, username, payload)
    payload
  rescue GitHubContextService::FetchError, Faraday::Error => e
    Rails.logger.warn "GitHubSnapshotService: skip snapshot for #{user.github_url}: #{e.message}"
    user.github_profile_snapshot&.payload.presence
  end

  private

  def stale?(snapshot)
    fetched_at = snapshot.fetched_at
    return true if fetched_at.blank?

    fetched_at < SNAPSHOT_TTL.ago
  end

  def upsert_snapshot(user, username, payload)
    snapshot = user.github_profile_snapshot || user.build_github_profile_snapshot
    snapshot.username = username
    snapshot.payload = payload
    snapshot.fetched_at = Time.current
    snapshot.save!
  end
end
