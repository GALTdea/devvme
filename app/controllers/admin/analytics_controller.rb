class Admin::AnalyticsController < ApplicationController
  before_action :require_admin
  before_action :set_time_range

  def index
    log_admin_activity("view_analytics_dashboard")

    @overview_stats = {
      total_users: User.count,
      active_users: User.active_users(@days),
      new_users: User.new_users_in_period(@days),
      total_views: total_views_in_period,
      engagement_rate: calculate_engagement_rate
    }
  end

  def registration_trends
    log_admin_activity("view_registration_trends", { time_range: @time_range, days: @days })

    @registration_data = {
      daily: User.registration_stats(@days),
      weekly: User.registration_stats_weekly(@days),
      monthly: User.registration_stats_monthly(@days)
    }

    @growth_rates = {
      daily_growth: calculate_daily_growth_rate,
      weekly_growth: calculate_weekly_growth_rate,
      monthly_growth: calculate_monthly_growth_rate,
      period_over_period: calculate_period_over_period_growth
    }

    @registration_insights = generate_registration_insights
  end

  def user_engagement
    log_admin_activity("view_user_engagement", { time_range: @time_range, days: @days })

    @engagement_metrics = {
      active_users: User.active_users(@days),
      daily_active_users: User.daily_active_users(@days),
      session_duration: calculate_average_session_duration,
      feature_usage: calculate_feature_usage,
      engagement_by_role: calculate_engagement_by_role,
      retention_rates: calculate_retention_rates
    }

    @engagement_trends = {
      daily_engagement: calculate_daily_engagement_trends,
      feature_adoption: calculate_feature_adoption_rates,
      user_activity_patterns: analyze_user_activity_patterns
    }
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

  # Registration Trends Methods
  def calculate_daily_growth_rate
    return 0 if @days < 2

    recent_days = User.registration_stats(7)
    previous_days = User.where(created_at: 14.days.ago..7.days.ago)
                       .group("DATE(created_at)")
                       .count

    return 0 if recent_days.empty? || previous_days.empty?

    recent_avg = recent_days.values.sum.to_f / recent_days.size
    previous_avg = previous_days.values.sum.to_f / previous_days.size

    return 0 if previous_avg == 0

    ((recent_avg - previous_avg) / previous_avg * 100).round(2)
  end

  def calculate_weekly_growth_rate
    return 0 if @days < 14

    current_week = User.where(created_at: 7.days.ago..Time.current).count
    previous_week = User.where(created_at: 14.days.ago..7.days.ago).count

    return 0 if previous_week == 0

    ((current_week - previous_week).to_f / previous_week * 100).round(2)
  end

  def calculate_monthly_growth_rate
    return 0 if @days < 60

    current_month = User.where(created_at: 30.days.ago..Time.current).count
    previous_month = User.where(created_at: 60.days.ago..30.days.ago).count

    return 0 if previous_month == 0

    ((current_month - previous_month).to_f / previous_month * 100).round(2)
  end

  def calculate_period_over_period_growth
    current_period = User.new_users_in_period(@days)
    previous_period = User.where(created_at: (@days * 2).days.ago..@days.days.ago).count

    return 0 if previous_period == 0

    ((current_period - previous_period).to_f / previous_period * 100).round(2)
  end

  def generate_registration_insights
    insights = []

    # Peak registration day
    daily_data = User.registration_stats(@days)
    if daily_data.any?
      peak_day = daily_data.max_by { |_, count| count }
      peak_date = peak_day[0].is_a?(String) ? Date.parse(peak_day[0]) : peak_day[0]
      insights << {
        type: 'peak_day',
        message: "Peak registration day: #{peak_date.strftime('%B %d')} with #{peak_day[1]} new users"
      }
    end

    # Growth trend
    growth_rate = calculate_daily_growth_rate
    if growth_rate > 10
      insights << {
        type: 'positive_growth',
        message: "Strong growth: #{growth_rate}% increase in daily registrations"
      }
    elsif growth_rate < -10
      insights << {
        type: 'negative_growth',
        message: "Declining registrations: #{growth_rate}% decrease in daily registrations"
      }
    end

    # Total registrations
    total_new = User.new_users_in_period(@days)
    insights << {
      type: 'total_registrations',
      message: "#{total_new} new users registered in the last #{@days} days"
    }

    insights
  end

  # User Engagement Methods
  def calculate_average_session_duration
    # Estimate session duration based on time between profile views
    # This is a simplified calculation - in a real app you'd track actual sessions
    profile_views = ProfileView.where(visited_at: @days.days.ago..Time.current)
                               .includes(:user)
                               .group_by(&:user_id)

    total_duration = 0
    session_count = 0

    profile_views.each do |user_id, views|
      sorted_views = views.sort_by(&:visited_at)
      next if sorted_views.size < 2

      # Calculate time between consecutive views (simplified session duration)
      (1...sorted_views.size).each do |i|
        duration = sorted_views[i].visited_at - sorted_views[i-1].visited_at
        if duration < 30.minutes # Consider it the same session if less than 30 minutes
          total_duration += duration
          session_count += 1
        end
      end
    end

    return 0 if session_count == 0

    (total_duration / session_count / 60).round(2) # Convert to minutes
  end

  def calculate_feature_usage
    {
      blog_posts_created: BlogPost.where(created_at: @days.days.ago..Time.current).count,
      projects_created: Project.where(created_at: @days.days.ago..Time.current).count,
      profile_views: ProfileView.where(visited_at: @days.days.ago..Time.current).count,
      users_with_content: User.joins(:blog_posts, :projects)
                              .where(created_at: @days.days.ago..Time.current)
                              .distinct.count
    }
  end

  def calculate_engagement_by_role
    role_stats = User.group(:role).count
    active_by_role = User.where('last_login_at > ?', @days.days.ago).group(:role).count

    role_stats.map do |role, count|
      active_count = active_by_role[role] || 0
      engagement_rate = count > 0 ? (active_count.to_f / count * 100).round(2) : 0

      {
        role: role,
        count: count,
        active_count: active_count,
        engagement_rate: engagement_rate
      }
    end
  end

  def calculate_retention_rates
    {
      day_1: calculate_retention_rate(1),
      day_7: calculate_retention_rate(7),
      day_30: calculate_retention_rate(30)
    }
  end

  def calculate_retention_rate(days)
    cohort_date = days.days.ago
    cohort_users = User.where(created_at: cohort_date.beginning_of_day..cohort_date.end_of_day)

    return 0 if cohort_users.empty?

    retained_users = cohort_users.select do |user|
      user.last_login_at && user.last_login_at > cohort_date
    end

    (retained_users.count.to_f / cohort_users.count * 100).round(2)
  end

  def calculate_daily_engagement_trends
    User.where(last_login_at: @days.days.ago..Time.current)
        .group("DATE(last_login_at)")
        .count
  end

  def calculate_feature_adoption_rates
    total_users = User.count
    return {} if total_users == 0

    {
      blog_adoption: (User.joins(:blog_posts).distinct.count.to_f / total_users * 100).round(2),
      project_adoption: (User.joins(:projects).distinct.count.to_f / total_users * 100).round(2),
      profile_completion: (User.where.not(bio: [nil, '']).count.to_f / total_users * 100).round(2)
    }
  end

  def analyze_user_activity_patterns
    # Analyze when users are most active
    hourly_activity = ProfileView.where(visited_at: @days.days.ago..Time.current)
                                 .group("EXTRACT(hour FROM visited_at)")
                                 .count

    {
      peak_hour: hourly_activity.max_by { |_, count| count }&.first,
      hourly_distribution: hourly_activity
    }
  end

  def calculate_engagement_rate
    total_users = User.count
    return 0 if total_users == 0

    active_users = User.active_users(@days)
    (active_users.to_f / total_users * 100).round(2)
  end

  def total_views_in_period
    BlogPost.where(created_at: @days.days.ago..Time.current).sum(:views_count) +
    ProfileView.where(visited_at: @days.days.ago..Time.current).count
  end
end
