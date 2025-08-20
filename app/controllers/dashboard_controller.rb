class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Dashboard main view - shows user statistics and recent activity
    @user = current_user

    # Calculate key metrics for dashboard widgets
    @projects_count = @user.projects_count
    @published_projects_count = @user.published_projects_count
    @profile_completion = @user.profile_completion_percentage

    # Get recent published projects for quick access (limit to 3)
    @recent_projects = @user.recent_projects(3)
  end
end
