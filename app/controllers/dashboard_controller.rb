class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @projects_count = @user.projects_count
    @published_projects_count = @user.published_projects_count
    @profile_completion = @user.profile_completion_percentage
    @recent_projects = @user.recent_projects(3)
  end
end
