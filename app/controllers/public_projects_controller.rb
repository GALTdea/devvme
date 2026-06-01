class PublicProjectsController < ApplicationController
  # Public project controller - no authentication required
  # Handles public viewing of published projects

  before_action :set_project, only: [:show, :ask_insight]
  before_action :set_cache_headers, only: [:index, :show]
  before_action :authenticate_user!, only: [:ask_insight]

  # GET /projects
  # Display all published projects with pagination and filtering
  def index
    @projects = Project.published
                      .includes(:user, thumbnail_attachment: :blob)
                      .by_explore_relevance

    # Filter by author (exact username match)
    if params[:author].present?
      @author = User.find_by(username: params[:author])
      if @author
        @projects = @projects.where(user: @author)
      end
    end

    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @projects = @projects.where(
        "title ILIKE ? OR description ILIKE ? OR project_story->>'overview' ILIKE ?",
        search_term, search_term, search_term
      )
    end

    # Filter by technology
    if params[:technology].present?
      @projects = @projects.where("technologies_used::text ILIKE ?", "%\"#{params[:technology]}\"%")
    end

    # Filter by user (partial match for search)
    if params[:user].present?
      @projects = @projects.joins(:user).where("users.username ILIKE ?", "%#{params[:user]}%")
    end

    # Pagination with Pagy
    @pagy, @projects = pagy(@projects, limit: 12)

    # Stats for header
    @total_projects = @author ? @author.projects.published.count : Project.published.count
    @total_users = User.joins(:projects).where(projects: { status: :published }).distinct.count

    @featured_stories = featured_stories_for_index if explore_filters_blank?
  end

  # GET /explore/:id
  # Display individual project (published to all; draft/archived to owner/admin only)
  def show
    unless can_view_project?
      redirect_to public_projects_path, alert: 'Project not found.'
      return
    end

    # Related projects: only published (so we don't leak draft titles)
    @related_projects = @project.user.projects
                               .published
                               .where.not(id: @project.id)
                               .includes(thumbnail_attachment: :blob)
                               .limit(3)

    prepare_project_seo_data if @project.published?
  end

  def ask_insight
    unless @project.published?
      redirect_to public_projects_path, alert: "Project not found."
      return
    end

    unless @project.project_insight_enabled?
      redirect_to public_project_path(@project), alert: "Project Insight is not enabled for this project."
      return
    end

    limiter = ProjectInsight::RateLimiter.new
    allowed, message = limiter.allowed?(user: current_user, project: @project)
    unless allowed
      redirect_to public_project_path(@project), alert: message
      return
    end

    @project_insight_result = ProjectInsight::AnswerService.call(
      project: @project,
      question: params[:question],
      user: current_user
    )
    limiter.track!(user: current_user, project: @project)

    @related_projects = @project.user.projects
                               .published
                               .where.not(id: @project.id)
                               .includes(thumbnail_attachment: :blob)
                               .limit(3)
    render :show, status: :ok
  rescue ProjectInsight::AnswerService::AnswerError, ArchitectService::MissingApiKeysError => e
    redirect_to public_project_path(@project), alert: e.message
  end

  private

  def explore_filters_blank?
    params[:search].blank? && params[:technology].blank? && params[:user].blank? && params[:author].blank?
  end

  def featured_stories_for_index
    Project.published
           .featured
           .includes(:user, thumbnail_attachment: :blob)
           .by_explore_relevance
           .limit(3)
  end

  def prepare_project_seo_data
    @seo_title = helpers.public_project_page_title(@project)
    @seo_description = helpers.public_project_meta_description(@project)
    @seo_image_url = helpers.public_project_social_image_url(@project, host: request.base_url)
    @seo_image_alt = helpers.public_project_social_image_alt(@project)
    @seo_project_url = public_project_url(@project)
  end

  def can_view_project?
    @project.published? || (user_signed_in? && (@project.user == current_user || current_user.can_access_admin?))
  end

  # Find project by ID with optimized includes
  def set_project
    @project = Project.includes(
      :user,
      thumbnail_attachment: :blob,
      images_attachments: :blob
    ).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to public_projects_path, alert: 'Project not found.'
  end

  # Set cache headers for better performance
  # Skip public caching when signed in so navbar and session-dependent content are always correct
  def set_cache_headers
    if user_signed_in?
      response.headers["Cache-Control"] = "private, no-cache, no-store, must-revalidate"
      return
    end

    # Cache public projects for 15 minutes (guests only)
    expires_in 15.minutes, public: true

    # Add ETag based on project updated_at timestamp for individual projects
    fresh_when(@project, public: true) if @project
  end
end
