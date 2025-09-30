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

  # URL validations with custom validation method
  validates :live_url, :source_code_url,
            presence: false,
            allow_blank: true
  validate :validate_url_format

  # Technologies used validation - ensures it's an array
  validate :technologies_used_format

  # Scopes for ordering and user filtering
  scope :by_display_order, -> { order(:display_order) }
  scope :recent, -> { order(created_at: :desc) }
  scope :featured, -> { where(featured: true) }
  scope :published, -> { where(status: :published) }
  scope :for_user, ->(user) { where(user: user) }

  # Class method to reorder projects for a user
  def self.reorder_for_user(user, project_ids)
    return false if user.blank? || project_ids.blank?

    # Ensure all project IDs belong to the user
    user_project_ids = user.projects.pluck(:id)
    valid_ids = project_ids.select { |id| user_project_ids.include?(id.to_i) }

    return false if valid_ids.empty?

    # Update display_order for each project
    ActiveRecord::Base.transaction do
      valid_ids.each_with_index do |project_id, index|
        user.projects.where(id: project_id).update_all(display_order: index + 1)
      end
    end

    true
  rescue StandardError => e
    Rails.logger.error "Failed to reorder projects: #{e.message}"
    false
  end

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

  # Validate URL format with user-friendly approach
  def validate_url_format
    validate_single_url(:live_url, "Live URL")
    validate_single_url(:source_code_url, "Source code URL")
  end

  def validate_single_url(field, field_name)
    url = self[field]
    return if url.blank?

    # Check for dangerous protocols first
    if url.match?(/\A(javascript|data|vbscript|file|ftp):/i)
      errors.add(field, "#{field_name} cannot use #{url.split(':').first} protocol for security reasons")
      return
    end

    # Normalize the URL for validation
    normalized_url = normalize_url_for_validation(url)

    # Use Ruby's URI class for more robust validation
    begin
      uri = URI.parse(normalized_url)

      # Ensure it's HTTP or HTTPS
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(field, "#{field_name} must be a valid web URL")
        return
      end

      # Ensure it has a host
      if uri.host.nil? || uri.host.empty?
        errors.add(field, "#{field_name} must include a domain name")
        return
      end

      # Basic domain validation - must have at least one dot, be localhost, or be a valid IP
      unless uri.host.include?('.') || uri.host == 'localhost' || valid_ip_address?(uri.host)
        errors.add(field, "#{field_name} must include a valid domain (e.g., example.com)")
        return
      end

    rescue URI::InvalidURIError
      errors.add(field, "#{field_name} format is invalid. Please enter a valid URL like 'example.com' or 'https://example.com'")
    end
  end

  def normalize_url_for_validation(url)
    # Add https:// if no protocol is present
    return url if url.match?(/\A[a-z][a-z0-9+.-]*:/i)
    "https://#{url}"
  end

  def valid_ip_address?(host)
    # Simple IP address validation (IPv4)
    host.match?(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/)
  end

  # Normalize URLs by adding https:// prefix if missing
  def normalize_urls
    normalize_url(:live_url)
    normalize_url(:source_code_url)
  end

  def normalize_url(field)
    url = self[field]
    return if url.blank?

    # Skip if already has protocol
    return if url.match?(/\A[a-z][a-z0-9+.-]*:/i)

    # Add https:// prefix for domain-only URLs
    self[field] = "https://#{url}"
  end
end
