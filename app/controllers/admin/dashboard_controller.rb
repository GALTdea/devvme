class Admin::DashboardController < ApplicationController
  before_action :require_admin
  before_action :set_time_range

  def index
    log_admin_activity("view_admin_dashboard")

    @user_stats = {
      total_users: User.total_users,
      active_users: User.active_users(@days),
      suspended_users: User.suspended_users,
      new_users_this_week: User.new_users_this_week,
      new_users_this_month: User.new_users_this_month,
      users_by_role: User.users_by_role,
      new_users_in_period: User.new_users_in_period(@days),
      active_users_today: User.active_users_today,
      online_users: User.online_users
    }

    @visitor_stats = {
      total_visitors: Visitor.total_visitors,
      active_visitors: Visitor.active_visitors(@days),
      online_visitors: Visitor.online_visitors,
      new_visitors_in_period: Visitor.new_visitors_in_period(@days),
      unique_visitors: Visitor.unique_visitors(@days),
      returning_visitors: Visitor.returning_visitors(@days),
      conversion_rate: Visitor.conversion_rate(@days)
    }

    @content_stats = {
      total_blog_posts: BlogPost.count,
      published_blog_posts: BlogPost.published_posts.count,
      archived_blog_posts: BlogPost.archived.count,
      total_projects: Project.count,
      published_projects: Project.published.count,
      new_content_in_period: new_content_in_period,
      total_views_in_period: total_views_in_period
    }

    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_blog_posts = BlogPost.includes(:user).order(created_at: :desc).limit(5)
    @recent_activities = AdminActivity.includes(:admin).recent.limit(10)

    @registration_chart_data = User.registration_stats(@days)
    @blog_views_chart_data = blog_views_stats(@days)
    @activity_chart_data = activity_stats(@days)
    @content_creation_chart_data = content_creation_stats(@days)
  end

  def export
    log_admin_activity("export_dashboard_data", { time_range: @time_range, days: @days })

    respond_to do |format|
      format.csv { send_data generate_csv_report, filename: "admin_dashboard_#{@time_range}_#{Date.current}.csv" }
      format.json { render json: generate_json_report }
    end
  end

  def online_users
    respond_to do |format|
      format.json { render json: { count: User.online_users } }
    end
  end

  def online_visitors
    respond_to do |format|
      format.json { render json: { count: Visitor.online_visitors } }
    end
  end

  private

  def set_time_range
    @time_range = params[:time_range] || '30_days'
    @days = case @time_range
            when '24_hours' then 1
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

  def blog_views_stats(days)
    # Get blog post views for the last N days
    BlogPost.joins(:user)
            .where("blog_posts.created_at > ?", days.days.ago)
            .group("DATE(blog_posts.created_at)")
            .sum(:views_count)
  end

  def activity_stats(days)
    AdminActivity.where("created_at > ?", days.days.ago)
                 .group("DATE(created_at)")
                 .order("DATE(created_at)")
                 .count
  end

  def content_creation_stats(days)
    blog_posts = BlogPost.where("created_at > ?", days.days.ago)
                         .group("DATE(created_at)")
                         .count
    projects = Project.where("created_at > ?", days.days.ago)
                      .group("DATE(created_at)")
                      .count

    # Merge the data by date
    all_dates = (blog_posts.keys + projects.keys).uniq.sort
    all_dates.map do |date|
      {
        date: date,
        blog_posts: blog_posts[date] || 0,
        projects: projects[date] || 0
      }
    end
  end

  def new_content_in_period
    {
      blog_posts: BlogPost.where("created_at > ?", @days.days.ago).count,
      projects: Project.where("created_at > ?", @days.days.ago).count
    }
  end

  def total_views_in_period
    BlogPost.where("created_at > ?", @days.days.ago).sum(:views_count) +
    ProfileView.where("visited_at > ?", @days.days.ago).count
  end

  def generate_csv_report
    require 'csv'

    CSV.generate do |csv|
      csv << ['Metric', 'Value', 'Period']
      # User metrics
      csv << ['Total Users', User.total_users, 'All Time']
      csv << ['Active Users', User.active_users(@days), "#{@days} days"]
      csv << ['New Users', User.new_users_in_period(@days), "#{@days} days"]
      csv << ['Suspended Users', User.suspended_users, 'All Time']
      csv << ['Online Users', User.online_users, 'Current']
      # Visitor metrics
      csv << ['Total Visitors', Visitor.total_visitors, 'All Time']
      csv << ['Active Visitors', Visitor.active_visitors(@days), "#{@days} days"]
      csv << ['New Visitors', Visitor.new_visitors_in_period(@days), "#{@days} days"]
      csv << ['Online Visitors', Visitor.online_visitors, 'Current']
      csv << ['Conversion Rate', "#{Visitor.conversion_rate(@days)}%", "#{@days} days"]
      # Content metrics
      csv << ['Total Blog Posts', BlogPost.count, 'All Time']
      csv << ['Published Blog Posts', BlogPost.published_posts.count, 'All Time']
      csv << ['Total Projects', Project.count, 'All Time']
      csv << ['Published Projects', Project.published.count, 'All Time']
      csv << ['Total Views', total_views_in_period, "#{@days} days"]
    end
  end

  def generate_json_report
    {
      time_range: @time_range,
      days: @days,
      generated_at: Time.current,
      user_stats: @user_stats,
      visitor_stats: @visitor_stats,
      content_stats: @content_stats,
      registration_chart_data: @registration_chart_data,
      blog_views_chart_data: @blog_views_chart_data,
      activity_chart_data: @activity_chart_data
    }
  end
end
