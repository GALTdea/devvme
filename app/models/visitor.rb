class Visitor < ApplicationRecord
  include BlogAnalytics

  has_many :visitor_page_views, dependent: :destroy
  belongs_to :user, optional: true

  validates :visitor_id, presence: true, uniqueness: true
  validates :first_visit_at, presence: true
  validates :last_visit_at, presence: true

  scope :recent, -> { order(last_visit_at: :desc) }
  scope :converted, -> { where(converted: true) }
  scope :not_converted, -> { where(converted: false) }
  scope :today, -> { where(first_visit_at: Date.current.all_day) }
  scope :this_week, -> { where(first_visit_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(first_visit_at: 1.month.ago..Time.current) }

  before_validation :generate_visitor_id, on: :create

  # Class methods for analytics
  def self.total_visitors
    count
  end

  def self.unique_visitors(days = 30)
    where("first_visit_at > ?", days.days.ago).count
  end

  def self.returning_visitors(days = 30)
    where("first_visit_at > ? AND visit_count > 1", days.days.ago).count
  end

  def self.conversion_rate(days = 30)
    total = where("first_visit_at > ?", days.days.ago).count
    return 0 if total == 0

    converted = where("first_visit_at > ? AND converted = true", days.days.ago).count
    (converted.to_f / total * 100).round(2)
  end

  def self.average_time_on_site(days = 30)
    avg_time = where("first_visit_at > ?", days.days.ago).average(:total_time_on_site)
    return 0 unless avg_time

    (avg_time / 60).round(2) # Convert to minutes
  end

  def self.average_page_views(days = 30)
    where("first_visit_at > ?", days.days.ago).average(:page_views)&.round(2) || 0
  end

  def self.visitors_by_date(days = 30)
    where("first_visit_at > ?", days.days.ago)
      .group("DATE(first_visit_at)")
      .order("DATE(first_visit_at)")
      .count
  end

  def self.top_referrers(limit = 10, days = 30)
    where("first_visit_at > ? AND referrer IS NOT NULL AND referrer != ?", days.days.ago, "")
      .group(:referrer)
      .order(Arel.sql("count(*) DESC"))
      .limit(limit)
      .count
  end

  def self.visitors_by_country(limit = 10, days = 30)
    where("first_visit_at > ? AND country IS NOT NULL", days.days.ago)
      .group(:country)
      .order(Arel.sql("count(*) DESC"))
      .limit(limit)
      .count
  end

  # Instance methods
  def mark_as_converted!(user)
    update!(converted: true, user: user)
  end

  def update_visit!
    update!(
      last_visit_at: Time.current,
      visit_count: visit_count + 1
    )
  end

  def add_page_view!(page_path, page_title: nil, referrer: nil, time_on_page: 0)
    visitor_page_views.create!(
      page_path: page_path,
      page_title: page_title,
      referrer: referrer,
      time_on_page: time_on_page,
      viewed_at: Time.current
    )

    increment!(:page_views)
    increment!(:total_time_on_site, time_on_page) if time_on_page > 0
  end

  def bounce_rate
    return 0 if page_views == 0
    page_views == 1 ? 100 : 0
  end

  def average_time_per_page
    return 0 if page_views == 0
    (total_time_on_site.to_f / page_views / 60).round(2) # in minutes
  end

  def returning_visitor?
    visit_count > 1
  end

  private

  def generate_visitor_id
    self.visitor_id ||= SecureRandom.uuid
  end
end
