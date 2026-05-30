# frozen_string_literal: true

module ProjectStoryBuilder
  class ContextBuilder
    def self.build(project:, rough_notes: nil)
      new.build(project:, rough_notes:)
    end

    def build(project:, rough_notes: nil)
      {
        "project" => project_metadata(project),
        "existing_story" => existing_story_fields(project),
        "github_signals" => github_signals(project),
        "repository_analysis" => repository_analysis(project),
        "rough_notes" => rough_notes.to_s.strip
      }.compact_blank
    end

    private

    def project_metadata(project)
      {
        "title" => project.title.to_s.strip,
        "description" => project.description.to_s.strip,
        "technologies" => Array(project.technologies_used).map(&:to_s).reject(&:blank?),
        "live_url" => project.live_url.to_s.strip,
        "source_code_url" => project.source_code_url.to_s.strip,
        "status" => project.status.to_s
      }.compact_blank
    end

    def existing_story_fields(project)
      ProjectStory::PUBLIC_STORY_FIELDS.index_with do |field|
        project.project_story[field].to_s.strip
      end.compact_blank
    end

    def github_signals(project)
      return nil unless project.github_insights_ready?

      summary = project.github_insights_summary
      return nil if summary.blank?

      {
        "project_overview" => summary["project_overview"],
        "tech_stack" => summary["tech_stack"],
        "highlights" => Array(summary["highlights"]).first(5),
        "caveats" => Array(summary["caveats"]).first(3)
      }.compact_blank
    end

    def repository_analysis(project)
      analysis = project.project_insight_analysis
      return nil if analysis.blank?

      analysis.slice("repository", "languages", "manifests", "readme_excerpt", "recent_commits", "structure")
    end
  end
end
