# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
    # Override create action to set users to pending_activation by default
  def create
    build_resource(sign_up_params)

    # Set account status to pending_activation for beta testing
    resource.account_status = :pending_activation

    resource.save
    yield resource if block_given?

    if resource.persisted?
      # Track visitor conversion
      track_visitor_conversion(resource)

      # Don't sign in the user, just redirect to beta confirmation
      set_flash_message! :notice, :signed_up_but_unconfirmed
      expire_data_after_sign_up!
      redirect_to beta_confirmation_path
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  # Override after_sign_up_path to handle beta users
  def after_sign_up_path_for(resource)
    if resource.pending_activation?
      beta_confirmation_path
    else
      super
    end
  end

  # Override after_inactive_sign_up_path for beta users
  def after_inactive_sign_up_path_for(resource)
    beta_confirmation_path
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
end
