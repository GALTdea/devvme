class VisitorPageView < ApplicationRecord
  include BlogPageViewAnalytics

  belongs_to :visitor

  validates :page_path, presence: true
  validates :viewed_at, presence: true

  scope :recent, -> { order(viewed_at: :desc) }
  scope :today, -> { where(viewed_at: Date.current.all_day) }
  scope :this_week, -> { where(viewed_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(viewed_at: 1.month.ago..Time.current) }

  # Analytics methods
  def self.total_page_views(days = 30)
    where("viewed_at > ?", days.days.ago).count
  end

  def self.unique_page_views(days = 30)
    where("viewed_at > ?", days.days.ago)
      .select(:visitor_id, :page_path)
      .distinct
      .count
  end

  def self.top_pages(limit = 10, days = 30)
    where("viewed_at > ?", days.days.ago)
      .group(:page_path)
      .order(Arel.sql("count(*) DESC"))
      .limit(limit)
      .count
  end

  def self.page_views_by_date(days = 30)
    where("viewed_at > ?", days.days.ago)
      .group("DATE(viewed_at)")
      .order("DATE(viewed_at)")
      .count
  end

  def self.average_time_on_page(days = 30)
    where("viewed_at > ? AND time_on_page > 0", days.days.ago)
      .average(:time_on_page)&.round(2) || 0
  end

  def self.exit_pages(limit = 10, days = 30)
    # Pages where visitors end their session (last page viewed)
    subquery = where("viewed_at > ?", days.days.ago)
                .select("visitor_id, MAX(viewed_at) as last_view")
                .group(:visitor_id)

    joins("INNER JOIN (#{subquery.to_sql}) last_views ON visitor_page_views.visitor_id = last_views.visitor_id AND visitor_page_views.viewed_at = last_views.last_view")
      .group(:page_path)
      .order(Arel.sql("count(*) DESC"))
      .limit(limit)
      .count
  end

  def self.entry_pages(limit = 10, days = 30)
    # Pages where visitors start their session (first page viewed)
    subquery = where("viewed_at > ?", days.days.ago)
                .select("visitor_id, MIN(viewed_at) as first_view")
                .group(:visitor_id)

    joins("INNER JOIN (#{subquery.to_sql}) first_views ON visitor_page_views.visitor_id = first_views.visitor_id AND visitor_page_views.viewed_at = first_views.first_view")
      .group(:page_path)
      .order(Arel.sql("count(*) DESC"))
      .limit(limit)
      .count
  end

  # Instance methods
  def time_on_page_minutes
    (time_on_page / 60.0).round(2)
  end

  def is_bounce?
    visitor.page_views == 1
  end
end
