# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :check_registration_enabled, only: [:new, :create]
  before_action :authenticate_user!, only: [:complete_profile, :update_profile]
  before_action :set_user_for_profile_completion, only: [:complete_profile, :update_profile]

  # Override create action to only require minimal fields (username, email, password)
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

      # Sign in the user and redirect to profile completion
      sign_in(resource)
      set_flash_message! :notice, :signed_up
      redirect_to complete_profile_registration_path, notice: "Welcome! Complete your profile to get started (optional)."
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # Show profile completion form (Step 2)
  def complete_profile
    # User is already authenticated and set via before_action
  end

  # Update profile with optional information (Step 2)
  def update_profile
    if @user.update(profile_completion_params)
      redirect_to dashboard_path, notice: "🎉 Profile updated successfully! Welcome to Devv.me."
    else
      flash.now[:alert] = "Please fix the errors below."
      render :complete_profile, status: :unprocessable_entity
    end
  end

  protected

  # Override after_sign_up_path to redirect to profile completion
  def after_sign_up_path_for(resource)
    complete_profile_registration_path
  end

  # Override after_inactive_sign_up_path to redirect to profile completion
  def after_inactive_sign_up_path_for(resource)
    complete_profile_registration_path
  end

  # Override sign_up_params to only permit minimal fields
  def sign_up_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end

  private

  def check_registration_enabled
    return if registration_enabled?

    render 'registration_disabled', layout: 'application'
  end

  def registration_enabled?
    # Registration is enabled if DISABLE_REGISTRATION is NOT set (blank)
    # If DISABLE_REGISTRATION is set to any value, registration is disabled

    # To force disable registration for testing/demo, uncomment the next line:
    # return false

    ENV['DISABLE_REGISTRATION'].blank?
  end

  def set_user_for_profile_completion
    @user = current_user
  end

  # Permit all optional profile fields for completion step
  def profile_completion_params
    params.require(:user).permit(
      :full_name, :bio, :github_url, :linkedin_url, :twitter_url,
      :website_url, :avatar, :job_title, :location, :headline,
      :contact_email, :skills_list
    )
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
