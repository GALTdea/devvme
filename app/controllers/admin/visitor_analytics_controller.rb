class Admin::VisitorAnalyticsController < ApplicationController
  before_action :require_admin
  before_action :set_time_range

  def index
    log_admin_activity("view_visitor_analytics", { time_range: @time_range, days: @days })

    @visitor_stats = {
      total_visitors: Visitor.total_visitors,
      unique_visitors: Visitor.unique_visitors(@days),
      returning_visitors: Visitor.returning_visitors(@days),
      conversion_rate: Visitor.conversion_rate(@days),
      average_time_on_site: Visitor.average_time_on_site(@days),
      average_page_views: Visitor.average_page_views(@days)
    }

    @page_view_stats = {
      total_page_views: VisitorPageView.total_page_views(@days),
      unique_page_views: VisitorPageView.unique_page_views(@days),
      average_time_on_page: VisitorPageView.average_time_on_page(@days)
    }

    @chart_data = {
      visitors_by_date: Visitor.visitors_by_date(@days),
      page_views_by_date: VisitorPageView.page_views_by_date(@days)
    }

    @top_data = {
      top_pages: VisitorPageView.top_pages(10, @days),
      entry_pages: VisitorPageView.entry_pages(10, @days),
      exit_pages: VisitorPageView.exit_pages(10, @days),
      top_referrers: Visitor.top_referrers(10, @days),
      visitors_by_country: Visitor.visitors_by_country(10, @days)
    }

    @recent_visitors = Visitor.recent.limit(10)
    @conversion_insights = generate_conversion_insights

    respond_to do |format|
      format.html
      format.json do
        render json: {
          unique_visitors: @visitor_stats[:unique_visitors],
          total_visitors: @visitor_stats[:total_visitors],
          conversion_rate: @visitor_stats[:conversion_rate],
          returning_visitors: @visitor_stats[:returning_visitors]
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

  def generate_conversion_insights
    insights = []

    total_visitors = Visitor.unique_visitors(@days)
    converted_visitors = Visitor.converted.where("first_visit_at > ?", @days.days.ago).count
    conversion_rate = Visitor.conversion_rate(@days)

    if total_visitors > 0
      insights << {
        type: 'conversion_summary',
        message: "#{converted_visitors} of #{total_visitors} visitors converted (#{conversion_rate}%)"
      }
    end

    # Top converting pages
    converting_visitors = Visitor.converted.where("first_visit_at > ?", @days.days.ago)
    if converting_visitors.any?
      # Get first page viewed by converted visitors
      first_pages = converting_visitors.joins(:visitor_page_views)
                                     .group('visitor_page_views.page_path')
                                     .order(Arel.sql('count(*) DESC'))
                                     .limit(1)
                                     .count

      if first_pages.any?
        top_converting_page = first_pages.first
        insights << {
          type: 'top_converting_page',
          message: "Top converting entry page: #{top_converting_page[0]} (#{top_converting_page[1]} conversions)"
        }
      end
    end

    # Bounce rate insight
    total_page_views = VisitorPageView.total_page_views(@days)
    single_page_visitors = Visitor.where("first_visit_at > ? AND page_views = 1", @days.days.ago).count

    if total_visitors > 0
      bounce_rate = (single_page_visitors.to_f / total_visitors * 100).round(2)
      insights << {
        type: 'bounce_rate',
        message: "Bounce rate: #{bounce_rate}% (#{single_page_visitors} single-page visits)"
      }
    end

    insights
  end
end
