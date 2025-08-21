class PublicBlogController < ApplicationController
  # Public blog - no authentication required
  before_action :set_blog_post, only: [:show]

  # GET /blog
  def index
    @blog_posts = BlogPost.published_posts.includes(:user)

    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @blog_posts = @blog_posts.where(
        "title ILIKE ? OR content ILIKE ? OR excerpt ILIKE ?",
        search_term, search_term, search_term
      )
    end

    # Pagination with Pagy
    @pagy, @blog_posts = pagy(@blog_posts, limit: 12)

    # Stats for header
    @total_posts = BlogPost.published_posts.count
  end

  # GET /blog/:id
  def show
    # Only show published posts to public
    unless @blog_post.published?
      redirect_to public_blog_index_path, alert: 'Blog post not found.'
      return
    end

    # Get next and previous posts for navigation
    @next_post = BlogPost.published_posts
                        .where("published_at > ?", @blog_post.published_at)
                        .order(published_at: :asc)
                        .first

    @previous_post = BlogPost.published_posts
                            .where("published_at < ?", @blog_post.published_at)
                            .order(published_at: :desc)
                            .first

    # Generate table of contents if post is long enough
    @toc = markdown_toc(@blog_post.content) if @blog_post.content.length > 2000
  end

  private

  def set_blog_post
    @blog_post = BlogPost.published_posts.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to public_blog_index_path, alert: 'Blog post not found.'
  end
end
