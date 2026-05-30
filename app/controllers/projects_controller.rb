class ProjectsController < ApplicationController
  # Authentication required for management actions only
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :reorder, :refresh_github_insights,
                                            :generate_story_suggestions, :apply_story_suggestions, :generate_resume_bullets]
  before_action :set_project, only: [:show, :edit, :update, :destroy, :refresh_github_insights,
                                     :generate_story_suggestions, :apply_story_suggestions, :generate_resume_bullets]
  before_action :ensure_owner_or_admin, only: [:edit, :update, :destroy, :refresh_github_insights,
                                                 :generate_story_suggestions, :apply_story_suggestions,
                                                 :generate_resume_bullets]

  def index
    # Show user's own projects if authenticated, otherwise redirect to public
    if user_signed_in?
      @projects = current_user.projects.by_display_order.includes(images_attachments: :blob)
    else
      redirect_to public_projects_path
    end
  end

  def show
    # Single canonical view: redirect to public project page (explore/:id)
    redirect_to public_project_path(@project)
  end

  def new
    @project = current_user.projects.build
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.save
      redirect_to public_project_path(@project), notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @story_suggestions = session.dig(:project_story_builder_suggestions, @project.id.to_s)
    @resume_bullets = session.dig(:project_resume_bullets, @project.id.to_s)
  end

  def update
    if @project.update(project_params)
      redirect_to public_project_path(@project), notice: "Project was successfully updated."
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
    redirect_path = refresh_github_insights_redirect_path

    unless FeatureFlags.github_project_enrichment_enabled_for?(current_user)
      redirect_to redirect_path, alert: "GitHub enrichment is not enabled for your account yet."
      return
    end

    unless @project.project_github_repo_url.present?
      redirect_to redirect_path, alert: "Add a valid GitHub Source Code URL before refreshing insights."
      return
    end

    if @project.github_insights_sync_status == "syncing"
      redirect_to redirect_path, alert: "GitHub insights sync is already in progress."
      return
    end

    GitHubInsightsSyncJob.perform_later(@project.id, sync_type: "deep", source: "manual")
    @project.update!(github_insights_sync_status: "queued", github_insights_last_error: nil)

    redirect_to redirect_path, notice: "GitHub insights refresh started."
  rescue StandardError => e
    Rails.logger.error("ProjectsController#refresh_github_insights failed for project #{@project.id}: #{e.message}")
    redirect_to redirect_path, alert: "Could not start GitHub insights refresh. Please try again."
  end

  def generate_story_suggestions
    limiter = ProjectStoryBuilder::RateLimiter.new
    allowed, message = limiter.allowed?(user: current_user, project: @project)
    unless allowed
      render_story_builder_error(message)
      return
    end

    @story_suggestions = ProjectStoryBuilder::GenerationService.call(
      project: @project,
      user: current_user,
      rough_notes: story_builder_rough_notes_param
    )
    limiter.track!(user: current_user, project: @project)
    store_story_builder_suggestions(@story_suggestions)
    @rough_notes = story_builder_rough_notes_param

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_project_path(@project, anchor: "story-builder"), notice: "Story suggestions generated." }
    end
  rescue ProjectStoryBuilder::GenerationService::GenerationError,
         ProjectStoryBuilder::ResultParser::ParseError,
         ArchitectService::MissingApiKeysError => e
    render_story_builder_error(e.message)
  end

  def generate_resume_bullets
    limiter = ProjectResumeBullets::RateLimiter.new
    allowed, message = limiter.allowed?(user: current_user, project: @project)
    unless allowed
      render_resume_bullets_error(message)
      return
    end

    @resume_bullets = ProjectResumeBullets::GenerationService.call(
      project: @project,
      user: current_user,
      emphasis: resume_bullets_emphasis_param
    )
    limiter.track!(user: current_user, project: @project)
    store_resume_bullets(@resume_bullets)
    @emphasis = resume_bullets_emphasis_param

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_project_path(@project, anchor: "resume-bullets"), notice: "Resume bullets generated." }
    end
  rescue ProjectResumeBullets::GenerationService::GenerationError,
         ProjectResumeBullets::ResultParser::ParseError,
         ArchitectService::MissingApiKeysError => e
    render_resume_bullets_error(e.message)
  end

  def apply_story_suggestions
    suggestions = fetch_story_builder_suggestions
    if suggestions.blank?
      redirect_to edit_project_path(@project, anchor: "story-builder"), alert: "Story suggestions expired. Generate a new draft first."
      return
    end

    applied_fields = ProjectStoryBuilder::ApplyService.call(
      project: @project,
      suggestions: suggestions,
      selections: params[:selections]
    )
    clear_story_builder_suggestions

    redirect_to edit_project_path(@project, anchor: "story-builder"),
                notice: "Applied #{applied_fields.size} story #{'field'.pluralize(applied_fields.size)}."
  rescue ProjectStoryBuilder::ApplyService::ApplyError => e
    redirect_to edit_project_path(@project, anchor: "story-builder"), alert: e.message
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

  def refresh_github_insights_redirect_path
    fallback = public_project_path(@project)
    referer = request.referer
    return fallback if referer.blank?

    referer_path = URI.parse(referer).path
    allowed_paths = [public_project_path(@project), edit_project_path(@project)]
    allowed_paths.include?(referer_path) ? referer_path : fallback
  rescue URI::InvalidURIError
    fallback
  end

  def project_params
    params.require(:project).permit(:title, :description, :live_url, :source_code_url,
                                   :featured, :status, :display_order, :technologies_display,
                                   :project_insight_enabled, :github_insights_enabled,
                                   :thumbnail, images: [],
                                   project_story: Project::STORY_FIELDS.map(&:to_sym))
  end

  def story_builder_rough_notes_param
    params[:rough_notes].to_s.strip
  end

  def resume_bullets_emphasis_param
    params[:emphasis].to_s.strip
  end

  def store_resume_bullets(bullets)
    session[:project_resume_bullets] ||= {}
    session[:project_resume_bullets][@project.id.to_s] = bullets
  end

  def fetch_resume_bullets
    session.dig(:project_resume_bullets, @project.id.to_s)
  end

  def render_resume_bullets_error(message)
    @resume_bullets_error = message
    @resume_bullets = fetch_resume_bullets
    @emphasis = resume_bullets_emphasis_param

    respond_to do |format|
      format.turbo_stream { render :generate_resume_bullets, status: :unprocessable_content }
      format.html { redirect_to edit_project_path(@project, anchor: "resume-bullets"), alert: message }
    end
  end

  def store_story_builder_suggestions(suggestions)
    session[:project_story_builder_suggestions] ||= {}
    session[:project_story_builder_suggestions][@project.id.to_s] = suggestions
  end

  def fetch_story_builder_suggestions
    session.dig(:project_story_builder_suggestions, @project.id.to_s)
  end

  def clear_story_builder_suggestions
    session[:project_story_builder_suggestions]&.delete(@project.id.to_s)
  end

  def render_story_builder_error(message)
    @story_builder_error = message
    @story_suggestions = fetch_story_builder_suggestions
    @rough_notes = story_builder_rough_notes_param

    respond_to do |format|
      format.turbo_stream { render :generate_story_suggestions, status: :unprocessable_content }
      format.html { redirect_to edit_project_path(@project, anchor: "story-builder"), alert: message }
    end
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
