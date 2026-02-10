# frozen_string_literal: true

module FeatureFlags
  ROLLOUT_OFF = "off"
  ROLLOUT_INTERNAL = "internal"
  ROLLOUT_ALL = "all"
  VALID_ROLLOUTS = [ROLLOUT_OFF, ROLLOUT_INTERNAL, ROLLOUT_ALL].freeze

  module_function

  def github_project_enrichment_rollout
    value = ENV.fetch(
      "GITHUB_PROJECT_ENRICHMENT_ROLLOUT",
      Rails.env.production? ? ROLLOUT_INTERNAL : ROLLOUT_ALL
    ).to_s.downcase
    VALID_ROLLOUTS.include?(value) ? value : ROLLOUT_INTERNAL
  end

  def github_project_enrichment_enabled?
    github_project_enrichment_rollout != ROLLOUT_OFF
  end

  def github_project_enrichment_internal_only?
    github_project_enrichment_rollout == ROLLOUT_INTERNAL
  end

  def github_project_enrichment_enabled_for?(user)
    return false unless github_project_enrichment_enabled?
    return true if github_project_enrichment_rollout == ROLLOUT_ALL

    user&.can_access_admin? || false
  end

  def github_project_enrichment_enabled_for_project?(project)
    return false if project.blank?
    return false unless github_project_enrichment_enabled?
    return true if github_project_enrichment_rollout == ROLLOUT_ALL

    project.user&.can_access_admin? || false
  end
end
