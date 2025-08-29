class SitemapController < ApplicationController
  before_action :set_cache_headers

  def index
    @base_url = request.base_url

    # Get all users with published content for sitemap
    @users = User.joins("LEFT JOIN projects ON users.id = projects.user_id AND projects.status = 'published'")
                 .joins("LEFT JOIN blog_posts ON users.id = blog_posts.user_id AND blog_posts.status = 'published'")
                 .where("projects.id IS NOT NULL OR blog_posts.id IS NOT NULL")
                 .distinct
                 .includes(avatar_attachment: :blob)
                 .order(:username)

    # Get published blog posts for sitemap
    @blog_posts = BlogPost.published_posts
                          .includes(:user)

    respond_to do |format|
      format.xml { render layout: false }
    end
  end

  private

  def set_cache_headers
    # Cache sitemap for 1 hour
    expires_in 1.hour, public: true

    # Set appropriate content type
    response.headers["Content-Type"] = "application/xml; charset=utf-8"
  end
end
