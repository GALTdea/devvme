class PublicProjectsController < ApplicationController
  # Public project controller - no authentication required
  # Handles public viewing of published projects

  before_action :set_project, only: [:show]
  before_action :set_cache_headers

  # GET /projects
  # Display all published projects with pagination and filtering
  def index
    @projects = Project.published
                      .includes(:user, thumbnail_attachment: :blob)
                      .order(created_at: :desc)

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
        "title ILIKE ? OR description ILIKE ?",
        search_term, search_term
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
  end

  # GET /projects/:id
  # Display individual published project
  def show
    # Only show published projects to public
    unless @project.published?
      redirect_to public_projects_path, alert: 'Project not found.'
      return
    end

    # Get related projects from the same user
    @related_projects = @project.user.projects
                               .published
                               .where.not(id: @project.id)
                               .includes(thumbnail_attachment: :blob)
                               .limit(3)
  end

  private

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
  def set_cache_headers
    # Cache public projects for 15 minutes
    expires_in 15.minutes, public: true

    # Add ETag based on project updated_at timestamp for individual projects
    fresh_when(@project, public: true) if @project
  end
end
