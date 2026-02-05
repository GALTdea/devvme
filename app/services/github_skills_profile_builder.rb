# frozen_string_literal: true

class GitHubSkillsProfileBuilder
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

  def self.build(data)
    new.build(data)
  end

  def build(data)
    repos = data["repos"].is_a?(Array) ? data["repos"] : []
    readmes = data["readmes"].is_a?(Hash) ? data["readmes"] : {}

    languages = repos.filter_map { |repo| repo.is_a?(Hash) ? repo["language"] : nil }
    topics = repos.flat_map { |repo| repo.is_a?(Hash) ? Array(repo["topics"]) : [] }
    readme_signals = extract_readme_signals(readmes)

    normalized_languages = normalize_skills(languages)
    normalized_topics = normalize_topics(topics)
    normalized_readme = normalize_skills(readme_signals)

    {
      "languages" => normalized_languages,
      "topics" => normalized_topics,
      "readme_signals" => normalized_readme,
      "combined" => normalize_skills(normalized_languages + normalized_topics + normalized_readme)
    }
  end

  private

  def extract_readme_signals(readmes)
    skills = []
    readmes.each_value do |readme|
      README_SKILL_PATTERNS.each do |pattern, canonical_skill|
        skills << canonical_skill if readme.to_s.match?(pattern)
      end
    end
    skills
  end

  def normalize_skills(skills)
    Array(skills).map { |s| s.to_s.strip }.reject(&:blank?).uniq
  end

  def normalize_topics(topics)
    Array(topics).map { |topic| topic.to_s.strip }.reject(&:blank?).map { |topic| titleize_topic(topic) }.uniq
  end

  def titleize_topic(topic)
    cleaned = topic.tr("_-", " ").strip
    cleaned.split.map { |part| titleize_token(part) }.join(" ")
  end

  def titleize_token(token)
    return token.upcase if token.length <= 2

    token.capitalize
  end
end
