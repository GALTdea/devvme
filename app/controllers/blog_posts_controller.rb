class BlogPostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_blog_post, only: [:show, :edit, :update, :destroy, :autosave, :archive, :unarchive]
  before_action :ensure_owner, only: [:show, :edit, :update, :destroy, :autosave, :archive, :unarchive]

  # GET /admin/blog
  def index
    @blog_posts = current_user.blog_posts.includes(:user)

    # Filter by status if specified
    case params[:status]
    when 'published'
      @blog_posts = @blog_posts.published
    when 'draft'
      @blog_posts = @blog_posts.draft
    when 'archived'
      @blog_posts = @blog_posts.archived
    else
      @blog_posts = @blog_posts.active
    end

    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      # Search in title, content (markdown), and excerpt
      # Note: Rich text content search can be added later if needed
      @blog_posts = @blog_posts.where(
        "title ILIKE ? OR content ILIKE ? OR excerpt ILIKE ?",
        search_term, search_term, search_term
      )
    end

    @blog_posts = @blog_posts.recent

    # Pagination with Pagy
    @pagy, @blog_posts = pagy(@blog_posts, limit: 15)

    # Stats for status tabs
    @published_count = current_user.blog_posts.published.count
    @draft_count = current_user.blog_posts.draft.count
    @archived_count = current_user.blog_posts.archived.count
    @total_count = current_user.blog_posts.count
  end

  # GET /blog/:id
  def show
    # Allow viewing own unpublished posts
    unless @blog_post.published? || @blog_post.user == current_user
      redirect_to blog_posts_path, alert: 'Blog post not found.'
      return
    end
  end

  # GET /blog/new
  def new
    @blog_post = current_user.blog_posts.build
  end

  # POST /blog
  def create
    @blog_post = current_user.blog_posts.build(blog_post_params)

    # Handle different form submission types
    case params[:commit]
    when 'Publish Post'
      @blog_post.published = true
      @blog_post.published_at ||= Time.current
    when 'Save Draft'
      @blog_post.published = false
      @blog_post.published_at = nil
    end

    if @blog_post.save
      if @blog_post.published?
        redirect_to @blog_post, notice: 'Blog post was published successfully!'
      else
        redirect_to @blog_post, notice: 'Blog post draft was saved successfully.'
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  # GET /blog/:id/edit
  def edit
  end

  # PATCH/PUT /blog/:id
  def update
    # Handle different form submission types
    case params[:commit]
    when 'Publish Post'
      params[:blog_post][:published] = true
      params[:blog_post][:published_at] ||= Time.current.iso8601
    when 'Save Draft'
      params[:blog_post][:published] = false
      params[:blog_post][:published_at] = nil
    end

    if @blog_post.update(blog_post_params)
      if @blog_post.published?
        redirect_to @blog_post, notice: 'Blog post was published successfully!'
      else
        redirect_to @blog_post, notice: 'Blog post was updated successfully.'
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /blog/:id
  def destroy
    @blog_post.destroy
    redirect_to blog_posts_path, notice: 'Blog post was successfully deleted.'
  end

  # POST /blog/:id/autosave
  def autosave
    if @blog_post.update(autosave_params)
      render json: {
        status: 'success',
        message: 'Draft saved',
        saved_at: Time.current.strftime('%H:%M:%S')
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to save draft',
        errors: @blog_post.errors.full_messages
      }
    end
  end

  # PATCH /blog/:id/archive
  def archive
    @blog_post.archive!
    redirect_to blog_posts_path, notice: 'Blog post was archived successfully.'
  end

  # PATCH /blog/:id/unarchive
  def unarchive
    @blog_post.unarchive!
    redirect_to blog_posts_path, notice: 'Blog post was unarchived successfully.'
  end

  private

  def set_blog_post
    @blog_post = BlogPost.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to blog_posts_path, alert: 'Blog post not found.'
  end

  def ensure_owner
    unless @blog_post.user == current_user
      redirect_to blog_posts_path, alert: 'You can only manage your own blog posts.'
    end
  end

  def blog_post_params
    params.require(:blog_post).permit(:title, :content, :excerpt, :published, :published_at, :featured, :editor_mode, :content_html)
  end

  def autosave_params
    params.require(:blog_post).permit(:title, :content, :excerpt, :editor_mode, :content_html)
  end
end
