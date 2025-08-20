class User < ApplicationRecord
  extend FriendlyId

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # FriendlyId configuration
  friendly_id :username, use: :slugged

  # Active Storage association for avatar
  has_one_attached :avatar

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

  # Validations
  validates :username, presence: true,
                      uniqueness: { case_sensitive: false },
                      length: { in: 3..30 },
                      format: { with: /\A[a-zA-Z0-9_-]+\z/,
                               message: "can only contain letters, numbers, hyphens, and underscores" }

  validates :full_name, length: { maximum: 100 }
  validates :bio, length: { maximum: 500 }

  validates :github_url, :linkedin_url, :website_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                     message: "must be a valid URL" },
            allow_blank: true

  # Avatar validations - ensures uploaded images meet requirements
  validate :avatar_format

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
    total_fields = 7
    completed_fields = 0

    # Count each completed profile field
    completed_fields += 1 if username.present?
    completed_fields += 1 if full_name.present?
    completed_fields += 1 if bio.present?
    completed_fields += 1 if avatar.attached?
    completed_fields += 1 if github_url.present?
    completed_fields += 1 if linkedin_url.present?
    completed_fields += 1 if website_url.present?

    # Return percentage rounded to nearest integer
    (completed_fields.to_f / total_fields * 100).round
  end

  def recent_projects(limit = 3)
    projects.published.recent.limit(limit)
  end

  def display_name
    full_name.present? ? full_name : username
  end

  private

  # Normalize URLs by adding https:// prefix if missing
  # This ensures all URLs are properly formatted for external links
  def normalize_urls
    normalize_url(:github_url)
    normalize_url(:linkedin_url)
    normalize_url(:website_url)
  end

  def normalize_url(field)
    url = self[field]
    return if url.blank?

    # Add https:// prefix if no protocol is specified
    unless url.start_with?("http://", "https://")
      self[field] = "https://#{url}"
    end
  end
end
