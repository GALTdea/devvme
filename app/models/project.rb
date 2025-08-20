class Project < ApplicationRecord
  belongs_to :user

  # Active Storage associations for project images
  has_many_attached :images
  has_one_attached :thumbnail

  # Enums for project status
  enum :status, {
    draft: 0,
    published: 1,
    archived: 2
  }, default: :draft

  # Validations according to requirements
  validates :title, presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # URL validations with auto-formatting
  validates :live_url, :source_code_url,
            format: { with: /\A(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?\z/i,
                     message: "must be a valid URL" },
            allow_blank: true

  # Technologies used validation - ensures it's an array
  validate :technologies_used_format

  # Scopes for ordering and user filtering
  scope :by_display_order, -> { order(:display_order) }
  scope :recent, -> { order(created_at: :desc) }
  scope :featured, -> { where(featured: true) }
  scope :published, -> { where(status: :published) }
  scope :for_user, ->(user) { where(user: user) }

  # Callbacks
  before_validation :set_display_order, on: :create
  before_save :normalize_urls

  # Technologies used getter - returns array of technologies
  def technologies_used
    super || []
  end

  # Technologies used setter - accepts array or comma-separated string
  def technologies_used=(value)
    case value
    when String
      # Handle comma-separated string input
      super(value.split(",").map(&:strip).reject(&:blank?))
    when Array
      super(value.reject(&:blank?))
    else
      super([])
    end
  end

  # Display technologies as comma-separated string for forms
  def technologies_display
    technologies_used.join(", ")
  end

  # Set technologies from display string (for form handling)
  def technologies_display=(value)
    self.technologies_used = value
  end

  private

  # Auto-set display_order to next available position for user
  def set_display_order
    return if display_order.present? || user.nil?

    last_order = user.projects.maximum(:display_order) || 0
    self.display_order = last_order + 1
  end

  # Validate technologies_used format
  def technologies_used_format
    unless technologies_used.is_a?(Array)
      errors.add(:technologies_used, "must be an array")
      return
    end

    if technologies_used.empty?
      errors.add(:technologies_used, "must include at least one technology")
      return
    end

    # Check each technology is a string and not too long
    technologies_used.each_with_index do |tech, index|
      unless tech.is_a?(String)
        errors.add(:technologies_used, "technology at position #{index + 1} must be text")
      end

      if tech.length > 50
        errors.add(:technologies_used, "technology '#{tech}' is too long (maximum 50 characters)")
      end
    end

    # Limit total number of technologies
    if technologies_used.length > 10
      errors.add(:technologies_used, "too many technologies (maximum 10)")
    end
  end

  # Normalize URLs by adding https:// prefix if missing
  def normalize_urls
    normalize_url(:live_url)
    normalize_url(:source_code_url)
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
