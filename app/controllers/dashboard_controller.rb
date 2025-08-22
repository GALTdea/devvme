class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Dashboard main view - shows user statistics and recent activity
    @user = current_user

    # Calculate key metrics for dashboard widgets
    @projects_count = @user.projects_count
    @published_projects_count = @user.published_projects_count
    @profile_completion = @user.profile_completion_percentage

    # Blog statistics
    @blog_posts_count = @user.blog_posts.count
    @published_blog_posts_count = @user.blog_posts.published.count
    @draft_blog_posts_count = @user.blog_posts.draft.count
    @total_blog_views = @user.blog_posts.sum(:views_count)
    @most_viewed_post = @user.blog_posts.published.by_popularity.first

    # Get recent published projects for quick access (limit to 3)
    @recent_projects = @user.recent_projects(3)

    # Get recent blog posts (limit to 3)
    @recent_blog_posts = @user.blog_posts.recent.limit(3)
  end
end
