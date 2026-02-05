# frozen_string_literal: true

module ContextBuilders
  class ProfileBuilder
    def build(user:, pasted_content:, github_data:, target_data: {})
      user_profile = {
        full_name: user.full_name,
        job_title: user.job_title,
        location: user.location,
        skills: user.skills.is_a?(Array) ? user.skills : [],
        github_url: user.github_url,
        linkedin_url: user.linkedin_url,
        bio: user.bio,
        headline: user.headline
      }.compact

      projects = user.projects.published.by_display_order.limit(20).map do |p|
        {
          title: p.title,
          description: p.description,
          technologies_used: p.technologies_used.is_a?(Array) ? p.technologies_used : []
        }
      end

      {
        "user_profile" => user_profile,
        "projects" => projects,
        "github" => github_data,
        "pasted_content" => pasted_content.to_s.strip.presence,
        "target_data" => target_data.presence
      }.compact
    end
  end
end
