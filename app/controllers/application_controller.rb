class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Include Pagy for pagination
  include Pagy::Backend

  # Configure permitted parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Track user login activity
  before_action :update_last_login, if: :user_signed_in?

  # Check if user is suspended
  before_action :check_user_suspension, if: :user_signed_in?

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

  def update_last_login
    current_user.update_last_login! if current_user.last_login_at.nil? || current_user.last_login_at < 1.hour.ago
  end

  def check_user_suspension
    if current_user.suspended?
      sign_out current_user
      redirect_to new_user_session_path, alert: "Your account has been suspended. Reason: #{current_user.suspension_reason}"
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
end
