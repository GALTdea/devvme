class User < ApplicationRecord
  extend FriendlyId

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Note: We handle email validation manually to allow reusing emails from deactivated users
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable

  # Override Devise's password validation for invited users
  def password_required?
    return false if invited? # Invited users don't need password initially
    return false if new_record? && will_be_invited? # Users about to be invited don't need password

    # Since we removed :validatable, implement the default Devise logic
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  # Helper method to check if user will be invited (used during creation)
  def will_be_invited?
    account_status == 'invited'
  end

  # FriendlyId configuration
  friendly_id :username, use: :slugged

  # Role system
  enum :role,{ user: 0, admin: 1, super_admin: 2 }

  # Scopes
  scope :featured, -> { where(featured: true) }

  # Account status system - tracks user activation state
  enum :account_status, {
    pending_activation: 0,  # User signed up but hasn't activated their account
    invited: 1,            # User invited by admin, profile visible but unclaimed
    active: 2,             # User account is active and verified
    suspended: 3,          # User account is suspended (uses existing suspension logic)
    deactivated: 4         # User has deactivated their own account
  }

  # Social card type system - controls which social media preview card to show
  enum :social_card_type, {
    automatic: 'automatic',      # Default: choose based on open_for_work status
    open_to_work: 'open_to_work', # Force open to work card
    professional: 'professional'  # Force professional card
  }

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

  # Visitor tracking associations
  has_many :visitors, dependent: :nullify

  # Following relationships
  has_many :active_follows, class_name: 'Follow', foreign_key: :follower_id, dependent: :destroy
  has_many :passive_follows, class_name: 'Follow', foreign_key: :followee_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followee
  has_many :followers, through: :passive_follows, source: :follower

  # Digest preferences
  has_one :digest_preference, class_name: 'UserDigestPreference', dependent: :destroy

  # Follow helpers
  def can_be_followed?
    active? || invited?
  end

  def follow!(other_user)
    return false if other_user == self
    return false unless other_user.can_be_followed?
    active_follows.find_or_create_by!(followee: other_user)
  end

  def unfollow!(other_user)
    active_follows.where(followee: other_user).destroy_all
  end

  def following?(other_user)
    following.exists?(other_user.id)
  end

  # Validations
  validates :username, presence: true,
                      uniqueness: { case_sensitive: false },
                      length: { in: 3..30 },
                      format: { with: /\A[a-zA-Z0-9_-]+\z/,
                               message: "can only contain letters, numbers, hyphens, and underscores" }

  # Custom email validation that allows reusing emails from deactivated users
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: {
    case_sensitive: false,
    conditions: -> { where.not(account_status: ['deactivated', 'suspended']) }
  }

  # Password validation (since we removed :validatable from Devise)
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :password, confirmation: true, if: :password_required?

  validates :full_name, length: { maximum: 100 }
  validates :bio, length: { maximum: 500 }

  validates :github_url, :linkedin_url, :website_url,
            format: { with: /\A(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?\z/i,
                     message: "must be a valid URL" },
            allow_blank: true

  validates :twitter_url,
            format: { with: /\A(https?:\/\/)?(twitter\.com\/|x\.com\/)?@?[a-zA-Z0-9_]{1,15}\z/i,
                     message: "must be a valid Twitter handle or URL" },
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

  # Work preferences validations (optional - only validate if present)
  validate :work_preferences_structure

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

  def work_preferences_structure
    return if work_preferences.blank? || work_preferences.empty?

    # Validate remote_preference if present
    if work_preferences['remote_preference'].present?
      valid_remote_prefs = %w[remote_only hybrid on_site flexible]
      unless valid_remote_prefs.include?(work_preferences['remote_preference'])
        errors.add(:work_preferences, "remote preference must be one of: #{valid_remote_prefs.join(', ')}")
      end
    end

    # Validate availability if present
    if work_preferences['availability'].present?
      valid_availabilities = %w[immediate 2_weeks 1_month 3_months_plus]
      unless valid_availabilities.include?(work_preferences['availability'])
        errors.add(:work_preferences, "availability must be one of: #{valid_availabilities.join(', ')}")
      end
    end

    # Validate work_types if present
    if work_preferences['work_types'].present?
      valid_work_types = %w[full_time part_time contract freelance]
      invalid_types = work_preferences['work_types'] - valid_work_types
      unless invalid_types.empty?
        errors.add(:work_preferences, "work types must be from: #{valid_work_types.join(', ')}")
      end
    end

    # Validate message length if present
    if work_preferences['message'].present? && work_preferences['message'].length > 500
      errors.add(:work_preferences, "message must be less than 500 characters")
    end

    # Validate preferred_roles if present (ensure it's an array)
    if work_preferences['preferred_roles'].present?
      unless work_preferences['preferred_roles'].is_a?(Array)
        errors.add(:work_preferences, "preferred roles must be an array")
      end
    end
  end

  # Callbacks for URL normalization
  before_save :normalize_urls

  # Set new users to pending activation status
  before_validation :set_pending_activation, on: :create

  # Create digest preferences for new users
  after_create :build_and_save_digest_preference

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
    total_fields = 13
    completed_fields = 0

    # Count each completed profile field
    completed_fields += 1 if username.present?
    completed_fields += 1 if full_name.present?
    completed_fields += 1 if bio.present?
    completed_fields += 1 if avatar.attached?
    completed_fields += 1 if github_url.present?
    completed_fields += 1 if linkedin_url.present?
    completed_fields += 1 if twitter_url.present?
    completed_fields += 1 if website_url.present?
    completed_fields += 1 if job_title.present?
    completed_fields += 1 if location.present?
    completed_fields += 1 if headline.present?
    completed_fields += 1 if contact_email.present?
    completed_fields += 1 if skills.present? && skills.any?

    # Return percentage rounded to nearest integer
    (completed_fields.to_f / total_fields * 100).round
  end

  # Skills handling - convert between JSON array and comma-separated string
  def skills_list
    return "" if skills.blank?
    skills.is_a?(Array) ? skills.join(", ") : skills.to_s
  end

  def skills_list=(value)
    if value.present?
      # Split by comma, strip whitespace, and remove empty strings
      self.skills = value.split(",").map(&:strip).reject(&:blank?)
    else
      self.skills = []
    end
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

  # Social image version management
  def bump_social_image_version!
    increment!(:social_image_version)
    Rails.logger.info "Bumped social image version for #{username} to #{social_image_version}"
  end

  def social_image_cache_key
    "v#{social_image_version}_#{social_card_type}_#{open_for_work?}"
  end

  # Extract Twitter handle from URL for display purposes
  def twitter_handle
    return nil if twitter_url.blank?

    # Extract handle from various Twitter URL formats
    # Examples: https://twitter.com/username, https://x.com/username, @username
    if twitter_url.include?('twitter.com/') || twitter_url.include?('x.com/')
      # Extract from full URL
      twitter_url.split('/').last&.gsub('@', '')
    elsif twitter_url.start_with?('@')
      # Remove @ symbol
      twitter_url.gsub('@', '')
    elsif twitter_url.start_with?('http')
      # If it starts with http but doesn't contain twitter.com or x.com, treat as handle
      twitter_url.gsub('@', '')
    else
      # If it's just a handle without URL or @, return as is
      twitter_url.gsub('@', '')
    end
  end

  # Generate Twitter profile URL from handle
  def twitter_profile_url
    return nil if twitter_handle.blank?
    "https://twitter.com/#{twitter_handle}"
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
    admin? || super_admin?
  end

  def update_last_login!
    update_column(:last_login_at, Time.current)
  end

  # Featured profile methods
  def toggle_featured!(admin: nil)
    new_featured_status = !featured
    update!(
      featured: new_featured_status,
      featured_at: new_featured_status ? Time.current : nil
    )
    log_admin_activity(admin, new_featured_status ? 'feature_user' : 'unfeature_user') if admin
  end

  # Account status methods
  def activate_account!(admin: nil)
    was_pending = pending_activation?
    update!(account_status: :active)

    # Send activation email if user was pending activation
    if was_pending
      begin
        UserActivationMailer.activation_notification(self).deliver_later
      rescue => e
        # Log the error but don't break the activation process
        Rails.logger.error "Failed to send activation email to #{email}: #{e.message}"
      end
    end

    log_admin_activity(admin, 'activate_user') if admin
  end

  def deactivate_account!(reason: nil, admin: nil)
    update!(
      account_status: :deactivated,
      suspended_at: Time.current,
      suspension_reason: reason
    )
    log_admin_activity(admin, 'deactivate_user', { reason: reason }) if admin
  end

  def can_access_application?
    (active? || invited?) && !suspended?
  end

  def activation_required?
    pending_activation?
  end

  # Invitation system methods
  def invite!(admin: nil, send_email: true)
    generate_invitation_token
    generate_invitation_access_code
    update!(
      account_status: :invited,
      invitation_accepted_at: nil
      # Note: invitation_sent_at will be updated by InvitationEmailService when email is actually sent
    )

    # Send invitation email using the enhanced service
    if send_email
      success = InvitationEmailService.send_invitation(self, admin)
      unless success
        Rails.logger.error "Failed to send invitation email to #{email} - check InvitationEmailService logs"
      end
    else
      # If not sending email, still update the timestamp for consistency
      update_column(:invitation_sent_at, Time.current)
    end

    log_admin_activity(admin, 'invite_user') if admin
    true
  end

  def claim_invitation!(password: nil, admin: nil)
    return false if invitation_expired? || !invited?

    # Update password if provided
    if password.present?
      self.password = password
      self.password_confirmation = password
    end

    update!(
      account_status: :active,
      invitation_accepted_at: Time.current
    )

    log_admin_activity(admin, 'claim_invitation') if admin
    true
  end

  def invitation_pending?
    invited? && invitation_token.present? && !invitation_expired?
  end

  def invitation_expired?
    return false unless invitation_sent_at.present?
    invitation_sent_at < 30.days.ago
  end

  def invitation_token_valid?(token)
    invitation_token.present? &&
    invitation_token == token &&
    invited? &&
    !invitation_expired?
  end

  def valid_access_code?(code)
    return false if invitation_access_code.blank?
    return false if code.blank?
    # Compare the codes securely
    ActiveSupport::SecurityUtils.secure_compare(
      invitation_access_code.to_s,
      code.to_s
    )
  end

  def access_code_verified?
    # Check if the session has verified the access code
    # This will be set by the controller
    @access_code_verified == true
  end

  def mark_access_code_verified!
    @access_code_verified = true
  end

  # Override suspended? to also check account_status
  def suspended?
    suspended_at.present? || account_status == 'suspended'
  end

  # Update suspend! to also update account_status
  def suspend!(reason: nil, admin: nil)
    update!(
      account_status: :suspended,
      suspended_at: Time.current,
      suspension_reason: reason
    )
    log_admin_activity(admin, 'suspend_user', { reason: reason }) if admin
  end

  # Update unsuspend! to reactivate account
  def unsuspend!(admin: nil)
    update!(
      account_status: :active,
      suspended_at: nil,
      suspension_reason: nil
    )
    log_admin_activity(admin, 'unsuspend_user') if admin
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

  def self.pending_activation_users
    where(account_status: :pending_activation).count
  end

  def self.active_users_by_status
    where(account_status: :active).count
  end

  def self.deactivated_users
    where(account_status: :deactivated).count
  end

  def self.users_by_account_status
    group(:account_status).count
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

  # Digest preference helpers - must be public for views/services
  def digest_preference_or_create
    digest_preference || build_and_save_digest_preference
  end

  # Work Status / Open for Work methods
  # These methods help manage the user's availability status and work preferences

  def open_to_work?
    open_for_work == true
  end

  def should_show_open_to_work_card?
    case social_card_type
    when 'open_to_work'
      true
    when 'professional'
      false
    when 'automatic'
      open_for_work?
    end
  end

  def work_status_message
    return nil unless open_to_work?
    work_preferences.dig('message') || 'Open to new opportunities'
  end

  def work_types
    work_preferences['work_types'] || []
  end

  def remote_preference
    work_preferences['remote_preference']
  end

  def availability
    work_preferences['availability']
  end

  def preferred_roles
    work_preferences['preferred_roles'] || []
  end

  def preferred_roles_list
    return '' if preferred_roles.empty?
    preferred_roles.is_a?(Array) ? preferred_roles.join(', ') : preferred_roles.to_s
  end

  # Human-readable labels for work preferences
  def remote_preference_label
    case remote_preference
    when 'remote_only' then 'Remote Only'
    when 'hybrid' then 'Hybrid'
    when 'on_site' then 'On-site'
    when 'flexible' then 'Flexible'
    else 'Not specified'
    end
  end

  def availability_label
    case availability
    when 'immediate' then 'Available Immediately'
    when '2_weeks' then 'Available in 2 Weeks'
    when '1_month' then 'Available in 1 Month'
    when '3_months_plus' then 'Available in 3+ Months'
    else 'Not specified'
    end
  end

  def work_types_labels
    return [] if work_types.empty?
    work_types.map do |type|
      case type
      when 'full_time' then 'Full-time'
      when 'part_time' then 'Part-time'
      when 'contract' then 'Contract'
      when 'freelance' then 'Freelance'
      else type.titleize
      end
    end
  end

  # Update work preferences
  def update_work_preferences(preferences_hash)
    # Clean up the preferences hash to only include valid keys
    cleaned_preferences = {}

    # Handle work_types as array
    if preferences_hash['work_types'].present?
      cleaned_preferences['work_types'] = Array(preferences_hash['work_types']).reject(&:blank?)
    end

    # Handle preferred_roles - can be comma-separated string or array
    if preferences_hash['preferred_roles'].present?
      roles = preferences_hash['preferred_roles']
      cleaned_preferences['preferred_roles'] = if roles.is_a?(String)
        roles.split(',').map(&:strip).reject(&:blank?)
      else
        Array(roles).reject(&:blank?)
      end
    end

    # Handle simple string fields
    %w[remote_preference availability message].each do |field|
      if preferences_hash[field].present?
        cleaned_preferences[field] = preferences_hash[field]
      end
    end

    # Merge with existing preferences
    self.work_preferences = work_preferences.merge(cleaned_preferences)
  end

  # Toggle open for work status
  def toggle_open_for_work!
    update!(open_for_work: !open_for_work)
  end

  private

  # Set new users to pending activation status (unless they're being invited)
  def set_pending_activation
    return if invited? # Don't override invited status
    self.account_status = :pending_activation if new_record?
  end

  # Generate secure invitation token
  def generate_invitation_token
    loop do
      self.invitation_token = SecureRandom.urlsafe_base64(32)
      break unless User.exists?(invitation_token: invitation_token)
    end
  end

  # Generate 6-digit access code for invitation verification
  def generate_invitation_access_code
    # Generate a random 6-digit code
    self.invitation_access_code = SecureRandom.random_number(1_000_000).to_s.rjust(6, '0')
  end

  # Normalize URLs by adding https:// prefix if missing
  # This ensures all URLs are properly formatted for external links
  def normalize_urls
    normalize_url(:github_url)
    normalize_url(:linkedin_url)
    normalize_url(:website_url)
    normalize_twitter_url
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

  def normalize_twitter_url
    url = self[:twitter_url]
    return if url.blank?

    # Only add https:// if it's a full URL, not just a handle
    if url.include?('twitter.com/') || url.include?('x.com/')
      # It's already a URL, normalize it
      unless url.start_with?("http://", "https://")
        self[:twitter_url] = "https://#{url}"
      end
    elsif url.start_with?('@')
      # It's a handle with @, keep as is
      self[:twitter_url] = url
    elsif url.start_with?("http://", "https://")
      # It's already a full URL, keep as is
      self[:twitter_url] = url
    else
      # It's just a handle without @, keep as is
      self[:twitter_url] = url
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

  private

  def build_and_save_digest_preference
    build_digest_preference.tap(&:save!)
  end
end
