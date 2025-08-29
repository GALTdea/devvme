class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def index
    log_admin_activity("view_admin_dashboard")

    @user_stats = {
      total_users: User.total_users,
      active_users: User.active_users(30),
      suspended_users: User.suspended_users,
      new_users_this_week: User.new_users_this_week,
      new_users_this_month: User.new_users_this_month,
      users_by_role: User.users_by_role
    }

    @content_stats = {
      total_blog_posts: BlogPost.count,
      published_blog_posts: BlogPost.published_posts.count,
      archived_blog_posts: BlogPost.archived.count,
      total_projects: Project.count,
      published_projects: Project.published.count
    }

    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_blog_posts = BlogPost.includes(:user).order(created_at: :desc).limit(5)
    @recent_activities = AdminActivity.includes(:admin).recent.limit(10)

    @registration_chart_data = User.registration_stats(30)
    @blog_views_chart_data = blog_views_stats(30)
  end

  private

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
end
