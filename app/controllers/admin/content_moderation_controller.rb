class Admin::ContentModerationController < ApplicationController
  before_action :require_admin
  before_action :set_blog_post, only: [:moderate_blog_post]
  before_action :set_project, only: [:moderate_project]

  include Pagy::Backend

  def index
    @recent_blog_posts = BlogPost.includes(:user).order(created_at: :desc).limit(5)
    @recent_projects = Project.includes(:user).order(created_at: :desc).limit(5)
    @flagged_content_count = 0 # This would connect to a flagging system if implemented

    @content_stats = {
      total_blog_posts: BlogPost.count,
      published_blog_posts: BlogPost.published_posts.count,
      archived_blog_posts: BlogPost.archived.count,
      total_projects: Project.count,
      published_projects: Project.published.count
    }
  end

  def blog_posts
    @pagy, @blog_posts = pagy(
      BlogPost.includes(:user).order(params[:sort] || 'created_at DESC'),
      limit: 20
    )

    # Apply filters
    @blog_posts = @blog_posts.published if params[:status] == 'published'
    @blog_posts = @blog_posts.where(published: false) if params[:status] == 'draft'
    @blog_posts = @blog_posts.archived if params[:status] == 'archived'

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @blog_posts = @blog_posts.where("title ILIKE ? OR content ILIKE ?", search_term, search_term)
    end

    if params[:user_id].present?
      @blog_posts = @blog_posts.where(user_id: params[:user_id])
    end
  end

  def projects
    @pagy, @projects = pagy(
      Project.includes(:user).order(params[:sort] || 'created_at DESC'),
      limit: 20
    )

    # Apply filters
    @projects = @projects.published if params[:status] == 'published'
    @projects = @projects.where(status: 'draft') if params[:status] == 'draft'

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @projects = @projects.where("title ILIKE ? OR description ILIKE ?", search_term, search_term)
    end

    if params[:user_id].present?
      @projects = @projects.where(user_id: params[:user_id])
    end
  end

  def moderate_blog_post
    action = params[:moderation_action]
    reason = params[:reason]

    case action
    when 'archive'
      @blog_post.update!(archived: true)
      action_taken = 'archived'
    when 'unarchive'
      @blog_post.update!(archived: false)
      action_taken = 'unarchived'
    when 'unpublish'
      @blog_post.update!(published: false, published_at: nil)
      action_taken = 'unpublished'
    when 'publish'
      @blog_post.update!(published: true, published_at: Time.current)
      action_taken = 'published'
    when 'delete'
      @blog_post.destroy!
      action_taken = 'deleted'
    else
      redirect_to admin_content_moderation_blog_posts_path, alert: 'Invalid moderation action.'
      return
    end

    log_admin_activity('moderate_blog_post', {
      action: action_taken,
      target_title: @blog_post.title,
      reason: reason,
      author_username: @blog_post.user.username
    })

    if action == 'delete'
      redirect_to admin_content_moderation_blog_posts_path, notice: "Blog post has been #{action_taken}."
    else
      redirect_to admin_content_moderation_blog_posts_path, notice: "Blog post has been #{action_taken}."
    end
  end

  def moderate_project
    action = params[:moderation_action]
    reason = params[:reason]

    case action
    when 'unpublish'
      @project.update!(status: 'draft')
      action_taken = 'unpublished'
    when 'publish'
      @project.update!(status: 'published')
      action_taken = 'published'
    when 'delete'
      @project.destroy!
      action_taken = 'deleted'
    else
      redirect_to admin_content_moderation_projects_path, alert: 'Invalid moderation action.'
      return
    end

    log_admin_activity('moderate_project', {
      action: action_taken,
      target_title: @project.title,
      reason: reason,
      author_username: @project.user.username
    })

    if action == 'delete'
      redirect_to admin_content_moderation_projects_path, notice: "Project has been #{action_taken}."
    else
      redirect_to admin_content_moderation_projects_path, notice: "Project has been #{action_taken}."
    end
  end

  private

  def set_blog_post
    @blog_post = BlogPost.find(params[:id])
  end

  def set_project
    @project = Project.find(params[:id])
  end

  def log_admin_activity(action, details = {})
    AdminActivity.create!(
      admin: current_user,
      action: action,
      target: @blog_post || @project,
      details: details,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
