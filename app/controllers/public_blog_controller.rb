class PublicBlogController < ApplicationController
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper

  # Override browser compatibility check to allow bots/crawlers
  # This is necessary because the browser gem blocks non-modern browsers,
  # but we need to allow social media crawlers (Twitterbot, etc.) to access blog posts
  def browser_compatible?
    return true if bot_request?
    super
  end

  # Public blog - no authentication required
  before_action :set_blog_post, only: [:show]

  private

  def bot_request?
    return false unless request.user_agent

    user_agent = request.user_agent.downcase
    bot_patterns = [
      "bot", "crawler", "spider", "scraper", "facebookexternalhit",
      "twitterbot", "linkedinbot", "googlebot", "bingbot", "yandexbot",
      "slurp", "duckduckbot", "baiduspider", "crawling"
    ]

    bot_patterns.any? { |pattern| user_agent.include?(pattern) }
  end

  # GET /blog
  def index
    @blog_posts = BlogPost.published_posts.includes(:user)

    # Filter by author
    if params[:author].present?
      @author = User.find_by(username: params[:author])
      if @author
        @blog_posts = @blog_posts.where(user: @author)
      end
    end

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
    @total_posts = @author ? @author.blog_posts.published.count : BlogPost.published_posts.count
  end

  # GET /blog/:id
  def show
    # Only show published posts to public
    unless @blog_post.published?
      redirect_to public_blog_index_path, alert: 'Blog post not found.'
      return
    end

    # Track view count (use a job to avoid blocking the request) [[memory:3928236]]
    TrackBlogPostViewJob.perform_later(@blog_post)

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

  # GET /blog.rss
  def rss
    @blog_posts = BlogPost.published_posts.includes(:user).limit(20)

    respond_to do |format|
      format.xml {
        render template: "public_blog/rss",
               layout: false,
               content_type: "application/rss+xml"
      }
    end
  end

  private

  def set_blog_post
    @blog_post = BlogPost.published_posts.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to public_blog_index_path, alert: 'Blog post not found.'
  end
end
