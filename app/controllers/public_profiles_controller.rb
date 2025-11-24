class PublicProfilesController < ApplicationController
  # Skip the user suspension check since we handle it in check_profile_access
  skip_before_action :check_user_suspension, if: :user_signed_in?

  before_action :set_user
  before_action :check_profile_access
  before_action :set_cache_headers

  # Display public user profile page that can be shared with visitors
  # Accessible at /:username (e.g., /gustavo)
  def show
    # Redirect authenticated active users to their private profile page
    # unless they explicitly want to preview their public profile
    # Exception: Don't redirect for unclaimed profiles since the user can't access dashboard
    # Exception: Don't redirect pending_activation users (they should see their public profile)
    if user_signed_in? && @user == current_user && !params[:preview] && !@unclaimed_profile && current_user.active?
      redirect_to profile_path
      return
    end

    # Track profile visit asynchronously (only for external visitors, not self-visits)
    # Don't track visits for unclaimed profiles
    track_profile_visit unless @user.invited?

    # Prepare unclaimed profile specific data
    if @unclaimed_profile
      prepare_unclaimed_profile_data
    else
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
    end

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

    # Allow access if user is pending_activation
    # Pending activation users can view their own profile and other public profiles like active users
    return if @user.pending_activation?

    # Allow public access to invited users (unclaimed profiles)
    # These profiles are publicly visible but marked as unclaimed
    if @user.invited?
      # Set unclaimed profile flag for views
      @unclaimed_profile = true
      return
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
    return unless @user

    if @unclaimed_profile
      # Cache unclaimed profiles for shorter duration (5 minutes)
      # since they might be claimed at any time
      expires_in 5.minutes, public: true

      # Add ETag based on user and invitation status
      # Use a simple string-based ETag for unclaimed profiles
      response.etag = "#{@user.id}-#{@user.updated_at.to_i}-#{@user.invitation_sent_at&.to_i}"
    else
      # For authenticated users, include follow status in cache key to prevent stale follow buttons
      if user_signed_in?
        # Shorter cache for authenticated users to ensure follow button accuracy
        expires_in 2.minutes, public: false

        # Include current user's follow status in ETag
        follow_status = current_user.following?(@user) ? 'following' : 'not_following'
        response.etag = "#{@user.id}-#{@user.updated_at.to_i}-#{current_user.id}-#{follow_status}"
      else
        # Longer cache for anonymous users (they don't see follow buttons)
        expires_in 15.minutes, public: true
        fresh_when(@user, public: true)
      end
    end
  end

  # Prepare data specific to unclaimed profiles
  def prepare_unclaimed_profile_data
    # No projects or blog posts for unclaimed profiles
    # They will be shown as "Coming soon when claimed"
    @recent_projects = []
    @recent_blog_posts = []

    # Set invitation-specific data for views
    @invitation_data = {
      sent_at: @user.invitation_sent_at,
      expires_at: @user.invitation_sent_at + 30.days,
      expired: @user.invitation_expired?,
      pending: @user.invitation_pending?,
      days_remaining: (@user.invitation_sent_at + 30.days - Time.current).to_i / 1.day
    }

    # Set limited functionality flags for views
    @profile_limitations = {
      no_contact: true,           # No contact buttons
      no_projects: true,          # No project creation/editing
      no_blog_posts: true,        # No blog post creation/editing
      no_interactions: true,      # No likes, comments, etc.
      show_claim_banner: true,    # Show prominent claim banner
      show_preview_notice: true   # Show "this is a preview" notice
    }
  end

  # Prepare SEO data that will be used in the view
  def prepare_seo_data
    # Basic meta description
    if @unclaimed_profile
      # Special SEO for unclaimed profiles
      if @user.bio.present?
        sanitized_bio = ActionView::Base.full_sanitizer.sanitize(@user.bio)
        @seo_description = "#{sanitized_bio} - This is an unclaimed developer profile on Devv.me."
      else
        @seo_description = "#{@user.display_name} - Unclaimed developer profile on Devv.me. Professional portfolio coming soon."
      end

      # Add unclaimed-specific keywords
      @seo_keywords = [
        @user.username,
        @user.display_name,
        "developer",
        "portfolio",
        "profile",
        "unclaimed",
        "coming soon"
      ].compact.join(", ")

      # Special title for unclaimed profiles
      @seo_title = "#{@user.display_name} (@#{@user.username}) - Unclaimed Profile"
    else
      # Regular SEO for active profiles
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
    end

    # Social media image URL for sharing (branded image)
    # Use path-based versioning for better Twitter cache busting
    @seo_avatar_url = social_profile_image_url(@user.username, @user.social_image_cache_key)

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
