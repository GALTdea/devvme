# == Schema Information
#
# Table name: projects
# Database name: primary
#
#  id                               :bigint           not null, primary key
#  demo_url                         :string
#  description                      :text
#  display_order                    :integer
#  featured                         :boolean
#  github_insights_enabled          :boolean          default(TRUE), not null
#  github_insights_last_error       :text
#  github_insights_last_synced_at   :datetime
#  github_insights_summary          :jsonb            not null
#  github_insights_sync_status      :string           default("never"), not null
#  github_url                       :string
#  live_url                         :string
#  project_insight_analysis         :jsonb            not null
#  project_insight_enabled          :boolean          default(FALSE), not null
#  project_insight_last_analyzed_at :datetime
#  source_code_url                  :string
#  status                           :integer
#  technologies                     :text
#  technologies_used                :json
#  title                            :string
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  user_id                          :bigint           not null
#
# Indexes
#
#  index_projects_on_display_order                (display_order)
#  index_projects_on_github_insights_enabled      (github_insights_enabled)
#  index_projects_on_github_insights_sync_status  (github_insights_sync_status)
#  index_projects_on_project_insight_enabled      (project_insight_enabled)
#  index_projects_on_status                       (status)
#  index_projects_on_user_id                      (user_id)
#  index_projects_on_user_id_and_display_order    (user_id,display_order)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Project < ApplicationRecord
  GITHUB_HOST_PATTERN = /\A(?:www\.)?github\.com\z/i

  belongs_to :user
  has_many :project_github_insight_snapshots, dependent: :destroy, class_name: "ProjectGitHubInsightSnapshot"

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
  validate :project_insight_source_url_required

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
  after_commit :enqueue_github_insights_sync, on: %i[create update]

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

  def project_insight_analysis
    super.presence || {}
  end

  def project_insight_ready?
    project_insight_enabled? && project_github_repo_url.present?
  end

  def github_insights_summary
    super.presence || {}
  end

  def github_insights_ready?
    github_insights_enabled? && github_insights_sync_status == "ready"
  end

  def github_insights_failed?
    github_insights_sync_status == "failed"
  end

  def github_insights_stale?(stale_after: 7.days)
    return true if github_insights_last_synced_at.blank?

    github_insights_last_synced_at < stale_after.ago
  end

  # Canonical repository URL resolver:
  # 1) source_code_url when it points to GitHub
  # 2) legacy github_url as fallback for older records
  def project_github_repo_url
    canonical_github_repo_url_for_values(source_code_url: source_code_url, legacy_url: github_url)
  end

  def github_repo_coordinates
    repo_url = project_github_repo_url
    return nil if repo_url.blank?

    uri = URI.parse(repo_url)
    segments = uri.path.to_s.split("/").reject(&:blank?)
    return nil if segments.size < 2

    owner = segments[0]
    repo = segments[1].sub(/\.git\z/i, "")
    return nil if owner.blank? || repo.blank?

    { owner: owner, repo: repo }
  rescue URI::InvalidURIError
    nil
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
    return nil if url.blank?

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

  def github_repo_url?(url)
    return false if url.blank?

    uri = URI.parse(url)
    return false unless uri.host.to_s.match?(GITHUB_HOST_PATTERN)

    segments = uri.path.to_s.split("/").reject(&:blank?)
    segments.size >= 2
  rescue URI::InvalidURIError
    false
  end

  def project_insight_source_url_required
    return unless project_insight_enabled?
    return if project_github_repo_url.present?

    errors.add(:project_insight_enabled, "requires a valid GitHub repository URL in source code URL (or legacy GitHub URL)")
  end

  def enqueue_github_insights_sync
    return unless should_enqueue_github_insights_sync?
    return unless defined?(GitHubInsightsSyncJob)

    GitHubInsightsSyncJob.perform_later(id, sync_type: "light", source: "auto")
    update_columns(github_insights_sync_status: "queued", github_insights_last_error: nil)
  rescue StandardError => e
    Rails.logger.error("Failed to enqueue GitHub insights sync for project #{id}: #{e.message}")
  end

  def should_enqueue_github_insights_sync?
    return false unless github_insights_enabled?
    return false if project_github_repo_url.blank?
    return true if previous_changes.key?("id")

    github_repo_url_changed_since_last_commit?
  end

  def github_repo_url_changed_since_last_commit?
    old_source_code_url = previous_changes.fetch("source_code_url", [source_code_url, source_code_url]).first
    old_github_url = previous_changes.fetch("github_url", [github_url, github_url]).first

    old_repo_url = canonical_github_repo_url_for_values(source_code_url: old_source_code_url, legacy_url: old_github_url)
    old_repo_url != project_github_repo_url
  end

  def canonical_github_repo_url_for_values(source_code_url:, legacy_url:)
    source = normalize_url_for_validation(source_code_url)
    return source if github_repo_url?(source)

    legacy = normalize_url_for_validation(legacy_url)
    return legacy if github_repo_url?(legacy)

    nil
  end
end
