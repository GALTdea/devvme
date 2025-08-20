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

  # Callbacks for URL normalization
  before_save :normalize_urls

  # Override FriendlyId should_generate_new_friendly_id? to regenerate slug when username changes
  def should_generate_new_friendly_id?
    username_changed? || super
  end

  private

  def normalize_urls
    normalize_url(:github_url)
    normalize_url(:linkedin_url)
    normalize_url(:website_url)
  end

  def normalize_url(field)
    url = self[field]
    return if url.blank?

    unless url.start_with?("http://", "https://")
      self[field] = "https://#{url}"
    end
  end
end
