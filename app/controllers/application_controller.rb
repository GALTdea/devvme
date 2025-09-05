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

  # Account activation check removed - users are now automatically active

  # Track visitors (non-signed-up users)
  before_action :track_visitor, unless: :user_signed_in?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :full_name, :bio, :github_url, :linkedin_url, :website_url, :avatar ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :full_name, :bio, :github_url, :linkedin_url, :website_url, :avatar ])
  end

  # Override Devise's after_sign_in_path_for to redirect to dashboard
  def after_sign_in_path_for(resource)
    dashboard_path
  end

  # Override Devise's after_sign_up_path_for to redirect to dashboard
  def after_sign_up_path_for(resource)
    # Track visitor conversion
    track_visitor_conversion(resource)
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
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def update_last_login
    current_user.update_last_login! if current_user.last_login_at.nil? || current_user.last_login_at < 1.hour.ago
  end

  def check_user_suspension
    if current_user.suspended?
      suspension_reason = current_user.suspension_reason
      sign_out current_user
      redirect_to new_user_session_path, alert: "Your account has been suspended. Reason: #{suspension_reason}"
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
