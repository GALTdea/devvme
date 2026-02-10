class ProjectsController < ApplicationController
  # Authentication required for management actions only
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :reorder, :refresh_github_insights]
  before_action :set_project, only: [:show, :edit, :update, :destroy, :refresh_github_insights]
  before_action :ensure_owner_or_admin, only: [:edit, :update, :destroy, :refresh_github_insights]

  def index
    # Show user's own projects if authenticated, otherwise redirect to public
    if user_signed_in?
      @projects = current_user.projects.by_display_order.includes(images_attachments: :blob)
    else
      redirect_to public_projects_path
    end
  end

  def show
    # Allow public access to published projects, or owner/admin access to any project
    unless @project.published? || can_edit_project?(@project)
      redirect_to public_projects_path, alert: 'Project not found.'
      return
    end
  end

  def new
    @project = current_user.projects.build
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.save
      redirect_to @project, notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @project.destroy!
    redirect_to projects_path, notice: "Project was successfully deleted."
  end

  def reorder
    project_ids = params[:project_ids]

    if Project.reorder_for_user(current_user, project_ids)
      render json: { status: "success", message: "Projects reordered successfully" }
    else
      render json: { status: "error", message: "Failed to reorder projects" }, status: :unprocessable_content
    end
  end

  def refresh_github_insights
    unless @project.project_github_repo_url.present?
      redirect_to edit_project_path(@project), alert: "Add a valid GitHub Source Code URL before refreshing insights."
      return
    end

    if @project.github_insights_sync_status == "syncing"
      redirect_to edit_project_path(@project), alert: "GitHub insights sync is already in progress."
      return
    end

    GitHubInsightsSyncJob.perform_later(@project.id, sync_type: "deep", source: "manual")
    @project.update!(github_insights_sync_status: "queued", github_insights_last_error: nil)

    redirect_to edit_project_path(@project), notice: "GitHub insights refresh started."
  rescue StandardError => e
    Rails.logger.error("ProjectsController#refresh_github_insights failed for project #{@project.id}: #{e.message}")
    redirect_to edit_project_path(@project), alert: "Could not start GitHub insights refresh. Please try again."
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def ensure_owner_or_admin
    unless can_edit_project?(@project)
      redirect_to projects_path, alert: "You don't have permission to perform this action."
    end
  end

  def project_params
    params.require(:project).permit(:title, :description, :live_url, :source_code_url,
                                   :featured, :status, :display_order, :technologies_display,
                                   :project_insight_enabled, :github_insights_enabled,
                                   :thumbnail, images: [])
  end

  # Permission helper methods
  def can_edit_project?(project)
    return false unless user_signed_in?
    project.user == current_user || current_user.can_access_admin?
  end

  def can_delete_project?(project)
    return false unless user_signed_in?
    project.user == current_user || current_user.can_access_admin?
  end

  # Make helper methods available to views
  helper_method :can_edit_project?, :can_delete_project?
end
