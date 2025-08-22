module CacheHelper
  # Generate cache key for user profile sections
  def profile_cache_key(user, section = nil)
    timestamp = [user.updated_at, user.avatar.attached? ? user.avatar.blob.updated_at : nil].compact.max
    key = "user-#{user.id}-#{timestamp.to_i}"
    key += "-#{section}" if section.present?
    key
  end

  # Generate cache key for projects section with dependencies
  def profile_projects_cache_key(user, projects)
    return "user-#{user.id}-projects-empty" if projects.empty?

    timestamps = [user.updated_at]
    projects.each do |project|
      timestamps << project.updated_at
      timestamps << project.thumbnail.blob.updated_at if project.thumbnail.attached?
    end

    max_timestamp = timestamps.compact.max
    "user-#{user.id}-projects-#{projects.count}-#{max_timestamp.to_i}"
  end

  # Generate cache key for blog posts section
  def profile_blog_posts_cache_key(user, blog_posts)
    return "user-#{user.id}-blog-posts-empty" if blog_posts.empty?

    timestamps = [user.updated_at] + blog_posts.map(&:updated_at)
    max_timestamp = timestamps.compact.max
    "user-#{user.id}-blog-posts-#{blog_posts.count}-#{max_timestamp.to_i}"
  end

  # Generate cache key for profile stats
  def profile_stats_cache_key(user)
    key_parts = [
      user.id,
      user.updated_at.to_i,
      user.projects.published.count,
      user.blog_posts.published.count,
      user.created_at.to_i
    ]
    "user-stats-#{key_parts.join('-')}"
  end
end
