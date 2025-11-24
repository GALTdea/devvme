class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Include Pagy for pagination
  include Pagy::Backend

  # Include Pundit for authorization
  include Pundit::Authorization

  # Pundit error handling
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Configure permitted parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Track user login activity
  before_action :update_last_login, if: :user_signed_in?

  # Check if user is suspended
  before_action :check_user_suspension, if: :user_signed_in?

  # Check if user account is pending activation
  before_action :check_pending_activation, if: :user_signed_in?

  # Check for limited access status (deactivated, suspended, etc.)
  before_action :check_limited_access, if: :user_signed_in?

  # Track visitors (non-signed-up users)
  before_action :track_visitor, unless: :user_signed_in?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :full_name, :bio, :github_url, :linkedin_url, :website_url, :avatar ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :full_name, :bio, :github_url, :linkedin_url, :website_url, :avatar ])
  end

  # Override Devise's after_sign_in_path_for to redirect based on account status
  def after_sign_in_path_for(resource)
    # Allow pending_activation users to access dashboard
    # They can see their own profile and dashboard even if not activated yet
    dashboard_path
  end

  # Override Devise's after_sign_up_path_for to redirect based on account status
  def after_sign_up_path_for(resource)
    # Track visitor conversion
    track_visitor_conversion(resource)

    # Allow pending_activation users to access dashboard and profile completion
    # They can see their own profile and dashboard even if not activated yet
    dashboard_path
  end

  # Admin authorization methods
  def require_admin
    unless current_user&.can_access_admin?
      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end

  def require_super_admin
    unless current_user&.can_manage_users?
      redirect_to root_path, alert: "Access denied. Super admin privileges required."
    end
  end

  private

  # Pundit configuration
  def pundit_user
    current_user
  end

  def user_not_authorized
    if current_user&.pending_activation?
      flash[:warning] = "Your account is pending activation. Please wait for an administrator to activate your account."
      redirect_to pending_activation_path
    else
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referrer || root_path)
    end
  end

  def update_last_login
    current_user.update_last_login! if current_user.last_login_at.nil? || current_user.last_login_at < 1.hour.ago
  end

  def check_user_suspension
    # Only handle suspended users, not deactivated users
    if current_user.suspended? && current_user.account_status != "deactivated"
      # Allow access to limited access pages
      return if request.path == suspended_path

      suspension_reason = current_user.suspension_reason
      sign_out current_user
      redirect_to new_user_session_path, alert: "Your account has been suspended. Reason: #{suspension_reason}"
    end
  end

  def check_pending_activation
    # Skip check for certain paths that pending users should be able to access
    return if should_skip_pending_check?

    if current_user.pending_activation?
      # Allow pending_activation users to access dashboard, profile, and profile completion
      # They can see their own profile and dashboard even if not activated yet
      # Only redirect to pending_activation if they're trying to access restricted areas
      # (like admin or other protected resources)

      # Don't redirect if they're on dashboard, profile, or profile completion
      allowed_paths = [dashboard_path, profile_path, edit_profile_path, "/users/complete_profile"]
      return if allowed_paths.include?(request.path) || request.path.start_with?("/#{current_user.friendly_id}")

      # For other restricted areas, show a warning but don't force redirect
      # The pending_activation page is informational, not mandatory
      unless flash[:warning]
        flash[:warning] = "Your account is pending activation. You will receive an email notification once your account is activated by an administrator."
      end
    end
  end

  # Enhanced method to check for any limited access status
  def check_limited_access
    return unless user_signed_in?

    case current_user.account_status
    when "pending_activation"
      check_pending_activation
    when "suspended"
      check_suspended_access
    when "deactivated"
      check_deactivated_access
    end
  end

  def check_suspended_access
    return if should_skip_pending_check?

    if current_user.suspended?
      unless flash[:alert]
        flash[:alert] = "Your account has been suspended. Reason: #{current_user.suspension_reason || 'No reason provided'}"
      end

      unless request.path == suspended_path
        redirect_to suspended_path
      end
    end
  end

  def check_deactivated_access
    return if should_skip_pending_check?

    if current_user.account_status == "deactivated"
      unless flash[:alert]
        flash[:alert] = "Your account has been deactivated."
      end

      unless request.path == deactivated_path
        redirect_to deactivated_path
      end
    end
  end


  def track_visitor_conversion(user)
    return unless user

    begin
      VisitorTrackingService.mark_conversion!(request, user)
    rescue => e
      # Log error but don't break the registration process
      Rails.logger.error "Failed to track visitor conversion: #{e.message}"
    end
  end

  def track_visitor
    return if should_skip_visitor_tracking?

    begin
      page_title = extract_page_title
      VisitorTrackingService.track_page_view(request, request.path, page_title: page_title)
    rescue => e
      # Log error but don't break the request
      Rails.logger.error "Failed to track visitor: #{e.message}"
    end
  end

  def should_skip_visitor_tracking?
    # Skip tracking for admin paths, API paths, and static assets
    return true if request.path.start_with?("/admin", "/api", "/rails")
    return true if request.path.match?(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|map)$/)
    return true if request.format.json? || request.format.xml?

    false
  end

  def should_skip_pending_check?
    # Skip limited access check for certain paths
    return true if request.path.start_with?("/admin", "/api", "/rails")
    return true if request.path.match?(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|map)$/)
    return true if request.format.json? || request.format.xml?
    return true if request.path == pending_activation_path
    return true if request.path == suspended_path
    return true if request.path == deactivated_path
    return true if request.path == new_user_session_path
    return true if request.path == destroy_user_session_path
    return true if request.path == root_path # Allow access to home page
    return true if request.path.start_with?("/public") # Allow access to public pages

    # Known routes that are accessible (defined before username route in routes.rb)
    known_public_routes = %w[/blog /explore /dashboard /beta /pending_activation /suspended /deactivated /sitemap.xml]
    return true if known_public_routes.include?(request.path) || request.path.start_with?("/blog/", "/explore/", "/beta/")

    # Allow profile completion path for newly registered users
    return true if request.path == "/users/complete_profile"

    # Allow users to view public profile pages (/:username routes)
    # This allows pending_activation users to view their own profile and other public profiles
    # The username pattern matches: [a-zA-Z0-9_-]+ and must be a single segment path
    # Check if path matches username pattern (single segment that looks like a username)
    if request.path.match?(%r{^/[a-zA-Z0-9_-]+$})
      # Exclude known single-segment routes that are not usernames
      excluded_single_segment_routes = %w[/blog /explore /dashboard /beta /pending_activation /suspended /deactivated /sitemap.xml /up]
      return true unless excluded_single_segment_routes.include?(request.path)
      # If it's a username-like path and not excluded, allow it (will route to PublicProfilesController)
      return true
    end

    # Allow deactivated users to view their own public profile
    if user_signed_in? && current_user.deactivated? && request.path == "/#{current_user.friendly_id}"
      return true
    end

    false
  end

  def extract_page_title
    case request.path
    when "/"
      "Home"
    when "/blog"
      "Blog"
    when %r{^/blog/\d+}
      "Blog Post"
    when %r{^/[^/]+$}
      "Profile"
    else
      request.path.split("/").last&.humanize || "Unknown"
    end
  end
end
