class Project < ApplicationRecord
  belongs_to :user

  # Active Storage associations
  has_many_attached :images
  has_one_attached :thumbnail

  # Enums
  enum :status, {
    draft: 0,
    published: 1,
    archived: 2
  }, default: :draft

  # Default values
  after_initialize :set_defaults, if: :new_record?

  # Validations
  validates :title, presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :technologies, presence: true, length: { maximum: 500 }

  validates :github_url, :demo_url,
            format: { with: /\A(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?\z/i,
                     message: "must be a valid URL" },
            allow_blank: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :featured, -> { where(featured: true) }
  scope :published, -> { where(status: :published) }

  # Callbacks
  before_save :normalize_urls

  private

  # Set default values for new records
  def set_defaults
    self.featured ||= false
    self.status ||= :draft
  end

  # Normalize URLs by adding https:// prefix if missing
  # This ensures all URLs are properly formatted for external links
  def normalize_urls
    normalize_url(:github_url)
    normalize_url(:demo_url)
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
