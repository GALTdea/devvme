class BlogPost < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  # Associations
  belongs_to :user
  has_rich_text :content_html  # Rich text content for Trix editor

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true
  validate :published_at_presence_when_published
  validate :content_presence_based_on_editor_mode

  # Scopes
  scope :published, -> { where(published: true, archived: false) }
  scope :draft, -> { where(published: false, archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :active, -> { where(archived: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_publication_date, -> { order(published_at: :desc) }
  scope :by_popularity, -> { order(views_count: :desc) }
  scope :published_before, ->(date) { published.where("published_at <= ?", date) }
  scope :published_after, ->(date) { published.where("published_at >= ?", date) }
  scope :most_viewed, ->(limit = 5) { published.by_popularity.limit(limit) }
  scope :featured, -> { where(featured: true) }

  # Callbacks
  before_validation :set_published_at, if: :published_changed?
  before_validation :set_default_editor_mode
  before_save :generate_excerpt_if_blank

  # Class methods
  def self.published_posts
    published.where("published_at <= ?", Time.current).by_publication_date
  end

  def self.recent_posts(limit = 5)
    published_posts.limit(limit)
  end

  # Instance methods
  def published?
    published && published_at.present? && published_at <= Time.current
  end

  def draft?
    !published?
  end

  def reading_time
    # Estimate reading time based on average 200 words per minute
    words = word_count
    (words / 200.0).ceil
  end

  def word_count
    text_content = if editor_mode == 'rich_text' && content_html.present?
      # Strip HTML tags and count words
      ActionController::Base.helpers.strip_tags(content_html.to_s)
    else
      content.to_s
    end
    text_content.split.size
  end

  # Get the actual content based on editor mode
  def display_content
    if editor_mode == 'rich_text' && content_html.present?
      content_html.to_s
    else
      content
    end
  end

  def to_param
    slug
  end

  # Analytics methods
  def increment_views!
    increment!(:views_count)
  end

  def popular?
    views_count > 100
  end

  # Archiving methods
  def archive!
    update!(archived: true)
  end

  def unarchive!
    update!(archived: false)
  end

  def archived?
    archived
  end

  def active?
    !archived?
  end

  private

  def set_published_at
    if published
      self.published_at ||= Time.current
    else
      self.published_at = nil
    end
  end

  def set_default_editor_mode
    self.editor_mode ||= 'markdown'
  end

  def generate_excerpt_if_blank
    return if excerpt.present?

    # Get plain text based on editor mode
    if editor_mode == 'rich_text' && content_html.present?
      # Strip HTML tags for rich text content
      plain_text = ActionController::Base.helpers.strip_tags(content_html.to_s)
                                         .gsub(/\n+/, " ")
                                         .strip
    else
      # Remove markdown syntax for markdown content
      plain_text = content.to_s.gsub(/[#*`_\[\]()!]/, "")
                          .gsub(/\n+/, " ")
                          .strip
    end

    # Take first 150 characters and ensure we don't cut off mid-word
    if plain_text.length > 150
      self.excerpt = plain_text[0..150].split(" ")[0..-2].join(" ") + "..."
    else
      self.excerpt = plain_text
    end
  end

  def published_at_presence_when_published
    if published && published_at.blank?
      errors.add(:published_at, "can't be blank when post is published")
    end
  end

  def content_presence_based_on_editor_mode
    if editor_mode == 'rich_text'
      if content_html.blank?
        errors.add(:content_html, "can't be blank")
      end
    else
      if content.blank?
        errors.add(:content, "can't be blank")
      end
    end
  end

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
end
