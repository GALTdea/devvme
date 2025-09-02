module BlogAnalytics
  extend ActiveSupport::Concern

  included do
    # Blog-specific visitor analytics methods
  end

  class_methods do
    # Blog visitor engagement metrics
    def blog_visitors(days = 30)
      joins(:visitor_page_views)
        .where("first_visit_at > ? AND visitor_page_views.page_path LIKE '/blog%'", days.days.ago)
        .distinct
        .count
    end

    def blog_page_views(days = 30)
      joins(:visitor_page_views)
        .where("first_visit_at > ? AND visitor_page_views.page_path LIKE '/blog%'", days.days.ago)
        .sum("visitors.page_views")
    end

    def blog_bounce_rate(days = 30)
      total_blog_visitors = blog_visitors(days)
      return 0 if total_blog_visitors == 0

      single_page_blog_visitors = joins(:visitor_page_views)
        .where("first_visit_at > ? AND visitor_page_views.page_path LIKE '/blog%' AND visitors.page_views = 1", days.days.ago)
        .distinct
        .count

      (single_page_blog_visitors.to_f / total_blog_visitors * 100).round(2)
    end

    def average_blog_time_on_site(days = 30)
      avg_time = joins(:visitor_page_views)
        .where("first_visit_at > ? AND visitor_page_views.page_path LIKE '/blog%'", days.days.ago)
        .average(:total_time_on_site)

      return 0 unless avg_time
      (avg_time / 60).round(2) # Convert to minutes
    end

    def blog_conversion_rate(days = 30)
      total_blog_visitors = blog_visitors(days)
      return 0 if total_blog_visitors == 0

      converted_blog_visitors = joins(:visitor_page_views)
        .where("first_visit_at > ? AND visitor_page_views.page_path LIKE '/blog%' AND converted = true", days.days.ago)
        .distinct
        .count

      (converted_blog_visitors.to_f / total_blog_visitors * 100).round(2)
    end

    def blog_to_signup_conversion_funnel(days = 30)
      # Visitors who viewed blog
      blog_viewers = blog_visitors(days)

      # Visitors who viewed blog then other pages
      blog_to_other_pages = joins(:visitor_page_views)
        .where("first_visit_at > ?", days.days.ago)
        .where("EXISTS (SELECT 1 FROM visitor_page_views vpv WHERE vpv.visitor_id = visitors.id AND vpv.page_path LIKE '/blog%')")
        .where("EXISTS (SELECT 1 FROM visitor_page_views vpv WHERE vpv.visitor_id = visitors.id AND vpv.page_path NOT LIKE '/blog%')")
        .distinct
        .count

      # Visitors who viewed blog then converted
      blog_to_conversion = joins(:visitor_page_views)
        .where("first_visit_at > ? AND converted = true", days.days.ago)
        .where("EXISTS (SELECT 1 FROM visitor_page_views vpv WHERE vpv.visitor_id = visitors.id AND vpv.page_path LIKE '/blog%')")
        .distinct
        .count

      {
        blog_viewers: blog_viewers,
        blog_to_other_pages: blog_to_other_pages,
        blog_to_conversion: blog_to_conversion,
        blog_engagement_rate: blog_viewers > 0 ? (blog_to_other_pages.to_f / blog_viewers * 100).round(2) : 0,
        blog_conversion_rate: blog_viewers > 0 ? (blog_to_conversion.to_f / blog_viewers * 100).round(2) : 0
      }
    end
  end
end
