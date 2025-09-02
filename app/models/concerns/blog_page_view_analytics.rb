module BlogPageViewAnalytics
  extend ActiveSupport::Concern

  class_methods do
    # Blog-specific page view analytics
    def blog_page_views(days = 30)
      where("viewed_at > ? AND page_path LIKE '/blog%'", days.days.ago).count
    end

    def blog_unique_page_views(days = 30)
      where("viewed_at > ? AND page_path LIKE '/blog%'", days.days.ago)
        .select(:visitor_id, :page_path)
        .distinct
        .count
    end

    def blog_average_time_on_page(days = 30)
      where("viewed_at > ? AND page_path LIKE '/blog%' AND time_on_page > 0", days.days.ago)
        .average(:time_on_page)&.round(2) || 0
    end

    def blog_index_vs_posts_views(days = 30)
      blog_views = where("viewed_at > ? AND page_path LIKE '/blog%'", days.days.ago)

      index_views = blog_views.where(page_path: '/blog').count
      post_views = blog_views.where("page_path LIKE '/blog/%' AND page_path != '/blog'").count

      {
        index_views: index_views,
        post_views: post_views,
        total_blog_views: index_views + post_views,
        index_to_post_ratio: index_views > 0 ? (post_views.to_f / index_views).round(2) : 0
      }
    end

    def most_popular_blog_posts(limit = 10, days = 30)
      where("viewed_at > ? AND page_path LIKE '/blog/%' AND page_path != '/blog'", days.days.ago)
        .group(:page_path)
        .order(Arel.sql('count(*) DESC'))
        .limit(limit)
        .count
    end

    def blog_engagement_by_hour(days = 7)
      where("viewed_at > ? AND page_path LIKE '/blog%'", days.days.ago)
        .group(Arel.sql("EXTRACT(hour FROM viewed_at)"))
        .order(Arel.sql("EXTRACT(hour FROM viewed_at)"))
        .count
    end

    def blog_reading_patterns(days = 30)
      blog_page_views = where("viewed_at > ? AND page_path LIKE '/blog%'", days.days.ago)

      # Calculate reading depth based on time on page
      reading_depth = blog_page_views
        .group("CASE
                 WHEN time_on_page < 30 THEN 'Quick scan (0-30s)'
                 WHEN time_on_page < 120 THEN 'Brief read (30s-2m)'
                 WHEN time_on_page < 300 THEN 'Engaged read (2-5m)'
                 WHEN time_on_page < 600 THEN 'Deep read (5-10m)'
                 ELSE 'Very deep read (10m+)'
               END")
        .order("MIN(time_on_page)")
        .count

      {
        reading_depth: reading_depth,
        average_reading_time: blog_page_views.average(:time_on_page)&.round(2) || 0,
        total_reading_time: blog_page_views.sum(:time_on_page) / 60.0 # in minutes
      }
    end

    def blog_referrer_analysis(days = 30)
      # Get visitors who came to blog from external sources
      blog_referrers = joins(:visitor)
        .where("viewed_at > ? AND page_path LIKE '/blog%'", days.days.ago)
        .where.not(referrer: [nil, ''])
        .group(:referrer)
        .order(Arel.sql('count(*) DESC'))
        .limit(10)
        .count

      # Internal blog navigation (blog index to blog posts)
      internal_blog_navigation = where("viewed_at > ? AND page_path LIKE '/blog/%' AND referrer LIKE '%/blog%'", days.days.ago).count

      {
        external_referrers: blog_referrers,
        internal_navigation: internal_blog_navigation
      }
    end

    def blog_exit_analysis(days = 30)
      # Pages where visitors exit after viewing blog content
      subquery = where("viewed_at > ?", days.days.ago)
                    .select("visitor_id, MAX(viewed_at) as last_view")
                    .group(:visitor_id)

      # Get exit pages for visitors who viewed blog content
      blog_visitor_exits = joins("INNER JOIN (#{subquery.to_sql}) last_views ON visitor_page_views.visitor_id = last_views.visitor_id AND visitor_page_views.viewed_at = last_views.last_view")
        .joins(:visitor)
        .where("EXISTS (SELECT 1 FROM visitor_page_views vpv WHERE vpv.visitor_id = visitor_page_views.visitor_id AND vpv.page_path LIKE '/blog%')")
        .group(:page_path)
        .order(Arel.sql('count(*) DESC'))
        .limit(10)
        .count

      {
        exit_pages: blog_visitor_exits,
        blog_exit_rate: calculate_blog_exit_rate(days)
      }
    end

    private

    def calculate_blog_exit_rate(days)
      blog_sessions = joins(:visitor)
        .where("viewed_at > ?", days.days.ago)
        .where("EXISTS (SELECT 1 FROM visitor_page_views vpv WHERE vpv.visitor_id = visitor_page_views.visitor_id AND vpv.page_path LIKE '/blog%')")
        .select(:visitor_id)
        .distinct
        .count

      return 0 if blog_sessions == 0

      blog_exits = joins(:visitor)
        .where("viewed_at > ? AND page_path LIKE '/blog%'", days.days.ago)
        .where("NOT EXISTS (SELECT 1 FROM visitor_page_views vpv WHERE vpv.visitor_id = visitor_page_views.visitor_id AND vpv.viewed_at > visitor_page_views.viewed_at)")
        .count

      (blog_exits.to_f / blog_sessions * 100).round(2)
    end
  end
end
