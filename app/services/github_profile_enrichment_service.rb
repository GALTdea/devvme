# frozen_string_literal: true

# Enriches user profile fields using GitHub context data.
# Merge strategy:
# - Never overwrite user-entered fields unless they are blank
# - Merge skills (deduped, case-insensitive)
class GitHubProfileEnrichmentService
  MAX_SKILLS = 20

  README_SKILL_PATTERNS = {
    /ruby on rails|rails/i => "Ruby on Rails",
    /\breact\b/i => "React",
    /\bnext\.?js\b/i => "Next.js",
    /\bnode\.?js\b/i => "Node.js",
    /\bexpress\b/i => "Express",
    /\btypescript\b/i => "TypeScript",
    /\bjavascript\b/i => "JavaScript",
    /\bpostgres(?:ql)?\b/i => "PostgreSQL",
    /\bmysql\b/i => "MySQL",
    /\bredis\b/i => "Redis",
    /\bdocker\b/i => "Docker",
    /\bkubernetes\b/i => "Kubernetes",
    /\bgithub actions\b/i => "GitHub Actions",
    /\baws\b|amazon web services/i => "AWS",
    /\bgcp\b|google cloud/i => "Google Cloud",
    /\bazure\b/i => "Azure"
  }.freeze

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
    skills = []

    repos = data["repos"].is_a?(Array) ? data["repos"] : []
    repos.each do |repo|
      language = repo.is_a?(Hash) ? repo["language"] : nil
      skills << language.to_s.strip if language.present?
    end

    readmes = data["readmes"].is_a?(Hash) ? data["readmes"] : {}
    readmes.each_value do |readme|
      README_SKILL_PATTERNS.each do |pattern, canonical_skill|
        skills << canonical_skill if readme.to_s.match?(pattern)
      end
    end

    normalize_skills(skills)
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
