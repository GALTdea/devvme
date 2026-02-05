# frozen_string_literal: true

# Enriches user profile fields using GitHub context data.
# Merge strategy:
# - Never overwrite user-entered fields unless they are blank
# - Merge skills (deduped, case-insensitive)
class GitHubProfileEnrichmentService
  MAX_SKILLS = 20

  def self.enrich_user!(user, github_data = nil)
    new.enrich_user!(user, github_data)
  end

  def enrich_user!(user, github_data = nil)
    data = github_data || GitHubContextService.fetch_for_user(user)
    return false if data.blank?

    profile = data["profile"].is_a?(Hash) ? data["profile"] : {}
    attrs = {}

    attrs[:full_name] = profile["name"].to_s.strip if user.full_name.blank? && profile["name"].present?
    attrs[:bio] = profile["bio"].to_s.strip if user.bio.blank? && profile["bio"].present?
    attrs[:location] = profile["location"].to_s.strip if user.location.blank? && profile["location"].present?
    attrs[:website_url] = profile["blog"].to_s.strip if user.website_url.blank? && profile["blog"].present?

    merged_skills = merge_skills(user.skills, extract_skills(data))
    attrs[:skills] = merged_skills if merged_skills != normalize_skills(user.skills)

    return false if attrs.empty?

    user.update(attrs)
  end

  private

  def extract_skills(data)
    skills_profile = GitHubSkillsProfileBuilder.build(data)
    normalize_skills(skills_profile["combined"])
  end

  def merge_skills(existing, inferred)
    merged = normalize_skills(existing)
    inferred.each do |skill|
      merged << skill unless merged.any? { |existing_skill| existing_skill.casecmp?(skill) }
    end
    merged.first(MAX_SKILLS)
  end

  def normalize_skills(skills)
    Array(skills).map { |s| s.to_s.strip }.reject(&:blank?).uniq
  end
end
