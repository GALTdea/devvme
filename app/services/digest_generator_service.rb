class DigestGeneratorService
  include ActiveModel::Model

  attr_accessor :user, :since_date

  def self.generate_digest_for_user(user)
    new(user: user).generate_digest
  end

  def initialize(user:, since_date: nil)
    @user = user
    @since_date = since_date || user.digest_preference_or_create.last_sent_at || 1.week.ago
  end

  def generate_digest
    return {} if @user.following.empty?

    digest_data = {}

    # Get all users being followed (only active ones)
    followed_users = @user.following.includes(:avatar_attachment)
                          .where(account_status: [:active, :invited])

    followed_users.each do |followed_user|
      user_content = collect_user_content(followed_user)

      # Only include users who have new content
      if user_content[:blog_posts].any? || user_content[:projects].any? || user_content[:profile_updates].any?
        digest_data[followed_user.username] = user_content
      end
    end

    digest_data
  end

  def total_content_count
    digest_data = generate_digest
    total = 0

    digest_data.each_value do |user_content|
      total += user_content[:blog_posts].count
      total += user_content[:projects].count
      total += user_content[:profile_updates].count
    end

    total
  end

  def has_content?
    total_content_count > 0
  end

  private

  def collect_user_content(followed_user)
    content = {
      user: followed_user,
      blog_posts: [],
      projects: [],
      profile_updates: []
    }

    # Get user's digest preferences
    user_prefs = @user.digest_preference_or_create

    # Collect blog posts if enabled
    if user_prefs.include_blog_posts?
      content[:blog_posts] = followed_user.blog_posts
                                         .published
                                         .where('published_at > ?', @since_date)
                                         .order(published_at: :desc)
                                         .limit(5) # Limit to prevent huge emails
    end

    # Collect projects if enabled
    if user_prefs.include_projects?
      content[:projects] = followed_user.projects
                                       .published
                                       .where('updated_at > ?', @since_date)
                                       .order(updated_at: :desc)
                                       .limit(5) # Limit to prevent huge emails
    end

    # Collect profile updates if enabled (optional feature)
    if user_prefs.include_profile_updates?
      content[:profile_updates] = collect_profile_updates(followed_user)
    end

    content
  end

  def collect_profile_updates(followed_user)
    updates = []

    # Check for recent profile changes (last 30 days)
    recent_changes = followed_user.updated_at > 30.days.ago

    if recent_changes
      # This is a simplified version - in a real app you might track specific field changes
      updates << "Updated profile information"
    end

    # Check for new skills (if we had skill change tracking)
    # This would require additional tracking in a real implementation

    updates
  end
end
