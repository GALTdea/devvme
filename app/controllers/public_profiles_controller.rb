class PublicProfilesController < ApplicationController
  # Skip the user suspension check since we handle it in check_profile_access
  skip_before_action :check_user_suspension, if: :user_signed_in?

  before_action :set_user
  before_action :check_profile_access
  before_action :set_cache_headers

  # Display public user profile page that can be shared with visitors
  # Accessible at /:username (e.g., /gustavo)
  def show
    # Redirect authenticated users to their private profile page
    # unless they explicitly want to preview their public profile
    if user_signed_in? && @user == current_user && !params[:preview]
      redirect_to profile_path
      return
    end

    # Track profile visit asynchronously (only for external visitors, not self-visits)
    track_profile_visit

    # Only show published projects to public visitors with optimized queries
    @recent_projects = @user.projects
                           .published
                           .includes(thumbnail_attachment: :blob)
                           .recent
                           .limit(6)

    # Only show published blog posts to public visitors
    @recent_blog_posts = @user.blog_posts
                             .published_posts
                             .limit(3)

    # Prepare SEO data for the view
    prepare_seo_data
  end

  private

  # Check if the current user can access the profile
  # Only account owners and admin users can view deactivated accounts
  def check_profile_access
    return if @user.nil? # Let set_user handle the 404

    # Allow access if user is active
    return if @user.active?

    # Redirect pending activation users to their limited access page
    if @user.pending_activation?
      if user_signed_in? && current_user == @user
        redirect_to pending_activation_path
        return
      else
        # Show 404 for pending users to unauthorized users
        render file: "#{Rails.root}/public/404-profile.html", status: :not_found, layout: false
        return
      end
    end

    # Redirect suspended users to their limited access page
    if @user.suspended? && !@user.deactivated?
      if user_signed_in? && current_user == @user
        redirect_to suspended_path
        return
      else
        # Show 404 for suspended users to unauthorized users
        render file: "#{Rails.root}/public/404-profile.html", status: :not_found, layout: false
        return
      end
    end

    # For deactivated accounts, only allow access to:
    # 1. The account owner (can view their own profile)
    # 2. Admin users (can view deactivated profiles)
    if @user.deactivated?
      if user_signed_in? && current_user == @user
        # Account owner can view their own profile
        return
      elsif user_signed_in? && current_user.can_access_admin?
        # Admin users can view deactivated profiles
        return
      else
        # Show 404 for deactivated accounts to unauthorized users
        render file: "#{Rails.root}/public/404-profile.html", status: :not_found, layout: false
        return
      end
    end
  end

  # Find user by username using FriendlyId with optimized includes
  # Returns 404 if user not found
  def set_user
    @user = User.friendly
                .includes(
                  avatar_attachment: :blob,
                  resume_attachment: :blob,
                  projects: {
                    thumbnail_attachment: :blob
                  },
                  blog_posts: []
                )
                .find(params[:username])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404-profile.html", status: :not_found, layout: false
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
    if @user.bio.present?
      sanitized_bio = ActionView::Base.full_sanitizer.sanitize(@user.bio)
      @seo_description = sanitized_bio.length > 155 ? "#{sanitized_bio[0..152]}..." : sanitized_bio
    else
      @seo_description = "View #{@user.display_name}'s profile and projects on Devvme App. #{@user.published_projects_count} published projects."
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

    # Social media image URL for sharing (branded image)
    @seo_avatar_url = social_profile_image_url(@user.username)

    # Full profile URL
    @seo_profile_url = request.original_url
  end

  # Track profile visit asynchronously for analytics
  def track_profile_visit
    # Only track if we have visitor information
    return unless request.remote_ip && request.user_agent

    # Queue the tracking job to run in the background
    TrackProfileViewJob.perform_later(
      @user.id,
      request.remote_ip,
      request.user_agent,
      request.referer
    )
  end
end
