# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
    # Override create action to set users to pending_activation by default
  def create
    build_resource(sign_up_params)

    # Account status will be set to active automatically via User model callback
    resource.save
    yield resource if block_given?

    if resource.persisted?
      # Track visitor conversion
      track_visitor_conversion(resource)

      # Send welcome email
      send_welcome_email(resource)

      # Sign in the user and redirect to dashboard
      sign_in(resource)
      set_flash_message! :notice, :signed_up
      redirect_to dashboard_path
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  # Override after_sign_up_path to redirect to dashboard
  def after_sign_up_path_for(resource)
    dashboard_path
  end

  # Override after_inactive_sign_up_path to redirect to dashboard
  def after_inactive_sign_up_path_for(resource)
    dashboard_path
  end

  private

  def track_visitor_conversion(user)
    return unless user

    begin
      VisitorTrackingService.mark_conversion!(request, user)
    rescue => e
      # Log error but don't break the registration process
      Rails.logger.error "Failed to track visitor conversion: #{e.message}"
    end
  end

  def send_welcome_email(user)
    return unless user

    begin
      UserWelcomeMailer.welcome_notification(user).deliver_later
    rescue => e
      # Log error but don't break the registration process
      Rails.logger.error "Failed to send welcome email to #{user.email}: #{e.message}"
    end
  end
end
