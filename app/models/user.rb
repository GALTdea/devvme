class User < ApplicationRecord
  extend FriendlyId

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # FriendlyId configuration
  friendly_id :username, use: :slugged

  # Role system
  enum :role,{ user: 0, admin: 1, super_admin: 2 }

  # Active Storage associations
  has_one_attached :avatar
  has_one_attached :resume

  # Avatar image variants for different display sizes
  # Used in navigation and small UI components
  def avatar_thumbnail
    avatar.variant(resize_to_fill: [ 50, 50 ])
  end

  # Used in profile pages and larger displays
  def avatar_medium
    avatar.variant(resize_to_fill: [ 200, 200 ])
  end

  # Project association
  has_many :projects, dependent: :destroy

  # Blog post association
  has_many :blog_posts, dependent: :destroy

  # Profile views association for analytics
  has_many :profile_views, dependent: :destroy

  # Admin activity associations
  has_many :admin_activities, foreign_key: :admin_id, dependent: :destroy

  # Validations
  validates :username, presence: true,
                      uniqueness: { case_sensitive: false },
                      length: { in: 3..30 },
                      format: { with: /\A[a-zA-Z0-9_-]+\z/,
                               message: "can only contain letters, numbers, hyphens, and underscores" }

  validates :full_name, length: { maximum: 100 }
  validates :bio, length: { maximum: 500 }

  validates :github_url, :linkedin_url, :website_url, :twitter_url,
            format: { with: /\A(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?\z/i,
                     message: "must be a valid URL" },
            allow_blank: true

  validates :job_title, length: { maximum: 100 }
  validates :location, length: { maximum: 100 }
  validates :headline, length: { maximum: 200 }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, length: { maximum: 20 }
  validates :resume_url, format: { with: /\A(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?\z/i,
                                   message: "must be a valid URL" }, allow_blank: true

  # File validations - ensures uploaded files meet requirements
  validate :avatar_format
  validate :resume_format

  def avatar_format
    return unless avatar.attached?

    # Check file type - only allow JPEG and PNG formats
    unless avatar.content_type.in?(%w[image/jpeg image/jpg image/png])
      errors.add(:avatar, "must be a JPEG or PNG image")
    end

    # Check file size - limit to 5MB to prevent large uploads
    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be less than 5MB")
    end
  end

  def resume_format
    return unless resume.attached?

    # Check file type - allow PDF and common document formats
    unless resume.content_type.in?(%w[application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document])
      errors.add(:resume, "must be a PDF or Word document")
    end

    # Check file size - limit to 10MB
    if resume.byte_size > 10.megabytes
      errors.add(:resume, "must be less than 10MB")
    end
  end

  # Callbacks for URL normalization
  before_save :normalize_urls

  # Override FriendlyId should_generate_new_friendly_id? to regenerate slug when username changes
  def should_generate_new_friendly_id?
    username_changed? || super
  end

  # Statistics methods for dashboard display
  def projects_count
    projects.count
  end

  def published_projects_count
    projects.published.count
  end

  # Calculates profile completion percentage based on filled fields
  # Used to encourage users to complete their profiles
  def profile_completion_percentage
    total_fields = 12
    completed_fields = 0

    # Count each completed profile field
    completed_fields += 1 if username.present?
    completed_fields += 1 if full_name.present?
    completed_fields += 1 if bio.present?
    completed_fields += 1 if avatar.attached?
    completed_fields += 1 if github_url.present?
    completed_fields += 1 if linkedin_url.present?
    completed_fields += 1 if website_url.present?
    completed_fields += 1 if job_title.present?
    completed_fields += 1 if location.present?
    completed_fields += 1 if headline.present?
    completed_fields += 1 if contact_email.present?
    completed_fields += 1 if skills.present? && skills.any?

    # Return percentage rounded to nearest integer
    (completed_fields.to_f / total_fields * 100).round
  end

  def recent_projects(limit = 3)
    projects.published.recent.limit(limit)
  end

  def featured_blog_posts(limit = 3)
    blog_posts.published_posts.featured.limit(limit)
  end

  def recent_blog_posts(limit = 3)
    blog_posts.published_posts.limit(limit)
  end

  def published_blog_posts_count
    blog_posts.published_posts.count
  end

  def display_name
    full_name.present? ? full_name : username
  end

  # Generate public profile URL for sharing
  def public_profile_url(base_url = nil)
    if base_url
      "#{base_url}/#{friendly_id}"
    else
      # This will be used with url helpers in controllers/views
      friendly_id
    end
  end

  # Generate shareable profile path
  def public_profile_path
    "/#{friendly_id}"
  end

  # Profile analytics methods
  def total_profile_views
    profile_views.count
  end

  def unique_profile_visitors
    profile_views.distinct.count(:visitor_ip)
  end

  def profile_views_today
    profile_views.today.count
  end

  def profile_views_this_week
    profile_views.this_week.count
  end

  def profile_views_this_month
    profile_views.this_month.count
  end

  def profile_views_by_date(days = 30)
    profile_views
      .where(visited_at: days.days.ago..Time.current)
      .group("DATE(visited_at)")
      .order("DATE(visited_at)")
      .count
  end

  def top_referrers(limit = 5)
    profile_views
      .where.not(referrer: [nil, ""])
      .joins("LEFT JOIN profile_views pv2 ON profile_views.referrer = pv2.referrer")
      .group(:referrer)
      .order("COUNT(*) DESC")
      .limit(limit)
      .count
  end

  # Admin and user management methods
  def suspended?
    suspended_at.present?
  end

  def suspend!(reason: nil, admin: nil)
    update!(
      suspended_at: Time.current,
      suspension_reason: reason
    )
    log_admin_activity(admin, 'suspend_user', { reason: reason }) if admin
  end

  def unsuspend!(admin: nil)
    update!(
      suspended_at: nil,
      suspension_reason: nil
    )
    log_admin_activity(admin, 'unsuspend_user') if admin
  end

  def can_access_admin?
    admin? || super_admin?
  end

  def can_manage_users?
    super_admin?
  end

  def update_last_login!
    update_column(:last_login_at, Time.current)
  end

  # Admin statistics methods
  def self.total_users
    count
  end

  def self.active_users(days = 30)
    where('last_login_at > ?', days.days.ago).count
  end

  def self.suspended_users
    where.not(suspended_at: nil).count
  end

  def self.new_users_this_week
    where('created_at > ?', 1.week.ago).count
  end

  def self.new_users_this_month
    where('created_at > ?', 1.month.ago).count
  end

  def self.users_by_role
    group(:role).count
  end

  def self.registration_stats(days = 30)
    where('created_at > ?', days.days.ago)
      .group("DATE(created_at)")
      .order("DATE(created_at)")
      .count
  end

  def self.new_users_in_period(days)
    where('created_at > ?', days.days.ago).count
  end

  def self.active_users_today
    where('last_login_at > ?', 1.day.ago).count
  end

  def self.online_users
    # Users who have been active in the last 15 minutes
    where('last_login_at > ?', 15.minutes.ago).count
  end

  def self.registration_stats_weekly(days)
    where('created_at > ?', days.days.ago)
      .group(Arel.sql("DATE_TRUNC('week', created_at)"))
      .order(Arel.sql("DATE_TRUNC('week', created_at)"))
      .count
  end

  def self.registration_stats_monthly(days)
    where('created_at > ?', days.days.ago)
      .group(Arel.sql("DATE_TRUNC('month', created_at)"))
      .order(Arel.sql("DATE_TRUNC('month', created_at)"))
      .count
  end

  def self.daily_active_users(days)
    where('last_login_at > ?', days.days.ago)
      .group("DATE(last_login_at)")
      .order("DATE(last_login_at)")
      .count
  end

  private

  # Normalize URLs by adding https:// prefix if missing
  # This ensures all URLs are properly formatted for external links
  def normalize_urls
    normalize_url(:github_url)
    normalize_url(:linkedin_url)
    normalize_url(:website_url)
    normalize_url(:twitter_url)
    normalize_url(:resume_url)
  end

  def normalize_url(field)
    url = self[field]
    return if url.blank?

    # Add https:// prefix if no protocol is specified
    unless url.start_with?("http://", "https://")
      self[field] = "https://#{url}"
    end
  end

  def log_admin_activity(admin, action, details = {})
    return unless admin&.can_access_admin?

    AdminActivity.create!(
      admin: admin,
      action: action,
      target_type: self.class.name,
      target_id: id,
      details: details.merge(
        target_username: username,
        target_email: email
      )
    )
  end
end
