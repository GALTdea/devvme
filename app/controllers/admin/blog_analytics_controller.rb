class Admin::BlogAnalyticsController < ApplicationController
  before_action :require_admin
  before_action :set_time_range

  def index
    log_admin_activity("view_blog_analytics", { time_range: @time_range, days: @days })

    # Blog visitor engagement metrics
    @blog_stats = {
      blog_visitors: Visitor.blog_visitors(@days),
      blog_page_views: VisitorPageView.blog_page_views(@days),
      blog_unique_page_views: VisitorPageView.blog_unique_page_views(@days),
      blog_bounce_rate: Visitor.blog_bounce_rate(@days),
      blog_conversion_rate: Visitor.blog_conversion_rate(@days),
      average_blog_time_on_site: Visitor.average_blog_time_on_site(@days),
      blog_average_time_on_page: VisitorPageView.blog_average_time_on_page(@days)
    }

    # Blog content performance
    @blog_content_stats = VisitorPageView.blog_index_vs_posts_views(@days)
    @most_popular_posts = VisitorPageView.most_popular_blog_posts(10, @days)
    @blog_reading_patterns = VisitorPageView.blog_reading_patterns(@days)

    # Blog traffic analysis
    @blog_referrer_analysis = VisitorPageView.blog_referrer_analysis(@days)
    @blog_exit_analysis = VisitorPageView.blog_exit_analysis(@days)

    # Blog engagement funnel
    @conversion_funnel = Visitor.blog_to_signup_conversion_funnel(@days)

    # Blog engagement by time
    @blog_hourly_engagement = VisitorPageView.blog_engagement_by_hour(7) # Last 7 days

    # Chart data
    @chart_data = {
      blog_views_by_date: blog_views_by_date(@days),
      blog_vs_other_pages: blog_vs_other_content(@days)
    }

    respond_to do |format|
      format.html
      format.json do
        render json: {
          blog_visitors: @blog_stats[:blog_visitors],
          blog_page_views: @blog_stats[:blog_page_views],
          blog_conversion_rate: @blog_stats[:blog_conversion_rate],
          blog_bounce_rate: @blog_stats[:blog_bounce_rate]
        }
      end
    end
  end

  private

  def set_time_range
    @time_range = params[:time_range] || '30_days'
    @days = case @time_range
            when '7_days' then 7
            when '30_days' then 30
            when '90_days' then 90
            when '1_year' then 365
            else 30
            end
  end

  def log_admin_activity(action, details = {})
    AdminActivity.create!(
      admin: current_user,
      action: action,
      details: details.merge(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      ),
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end

  def blog_views_by_date(days)
    VisitorPageView.where("viewed_at > ? AND page_path LIKE '/blog%'", days.days.ago)
      .group("DATE(viewed_at)")
      .order("DATE(viewed_at)")
      .count
  end

  def blog_vs_other_content(days)
    total_views = VisitorPageView.where("viewed_at > ?", days.days.ago).count
    blog_views = VisitorPageView.blog_page_views(days)
    other_views = total_views - blog_views

    {
      blog_views: blog_views,
      other_views: other_views,
      blog_percentage: total_views > 0 ? (blog_views.to_f / total_views * 100).round(2) : 0
    }
  end
end
