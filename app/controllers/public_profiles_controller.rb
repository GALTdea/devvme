class PublicProfilesController < ApplicationController
  before_action :set_user
  before_action :set_cache_headers

  # Display public user profile page that can be shared with visitors
  # Accessible at /:username (e.g., /gustavo)
  def show
    # If current user is viewing their own profile, redirect to authenticated profile
    if user_signed_in? && @user == current_user
      redirect_to profile_path
      return
    end

    # Only show published projects to public visitors
    @recent_projects = @user.projects.published.recent.limit(6)

    # Only show published blog posts to public visitors
    @recent_blog_posts = @user.blog_posts.published.recent.limit(3)

    # Prepare SEO data for the view
    prepare_seo_data
  end

  private

  # Find user by username using FriendlyId
  # Returns 404 if user not found
  def set_user
    @user = User.friendly.find(params[:username])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end

    # Set cache headers for better performance
  def set_cache_headers
    # Cache public profiles for 15 minutes
    expires_in 15.minutes, public: true

    # Add ETag based on user updated_at timestamp
    fresh_when(@user, public: true) if @user
  end

  # Prepare SEO data that will be used in the view
  def prepare_seo_data
    # Basic meta description
    @seo_description = if @user.bio.present?
                        sanitized_bio = ActionView::Base.full_sanitizer.sanitize(@user.bio)
                        sanitized_bio.length > 155 ? "#{sanitized_bio[0..152]}..." : sanitized_bio
                      else
                        "View #{@user.display_name}'s profile and projects on Devvme App. #{@user.published_projects_count} published projects."
                      end

    # Keywords based on user's profile
    @seo_keywords = [
      @user.username,
      @user.display_name,
      "developer",
      "portfolio",
      "projects",
      "profile"
    ].compact.join(", ")

    # Page title
    @seo_title = "#{@user.display_name} (@#{@user.username})"

    # Avatar URL for social sharing
    @seo_avatar_url = @user.avatar.attached? ? url_for(@user.avatar) : nil

    # Full profile URL
    @seo_profile_url = request.original_url
  end
end
