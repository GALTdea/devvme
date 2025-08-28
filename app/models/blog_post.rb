class BlogPost < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  # Associations
  belongs_to :user

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :published_at_presence_when_published

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
    word_count = content.split.size
    (word_count / 200.0).ceil
  end

  def word_count
    content.split.size
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

  def generate_excerpt_if_blank
    return if excerpt.present?

    # Remove markdown syntax for excerpt
    plain_text = content.gsub(/[#*`_\[\]()!]/, "")
                       .gsub(/\n+/, " ")
                       .strip

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

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
end
