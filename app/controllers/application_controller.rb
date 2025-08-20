class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Configure permitted parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :full_name, :bio, :github_url, :linkedin_url, :website_url, :avatar])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :full_name, :bio, :github_url, :linkedin_url, :website_url, :avatar])
  end
end
