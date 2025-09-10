class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user


  # Show profile edit form
  def edit
  end

  # Update user profile with validation and proper error handling
  def update
    if @user.update(profile_params)
      redirect_to dashboard_path, notice: "Profile updated successfully!"
    else
      # Re-render edit form with validation errors
      render :edit, status: :unprocessable_entity
    end
  end

  # Show profile completion page with missing fields
  def complete
    @missing_fields = identify_missing_fields
    @completion_percentage = @user.profile_completion_percentage
  end

  private

  # Set current user for all profile actions
  def set_user
    @user = current_user
  end

  # Strong parameters for profile updates
  # Only allows specific profile fields to be updated
  def profile_params
    params.require(:user).permit(:username, :full_name, :bio, :github_url, :linkedin_url, :website_url, :avatar, :job_title, :location, :headline, :contact_email, :skills_list)
  end

  # Identify missing profile fields for completion page
  def identify_missing_fields
    missing_fields = []

    missing_fields << { name: "Username", field: :username, path: edit_profile_path } unless @user.username.present?
    missing_fields << { name: "Full Name", field: :full_name, path: edit_profile_path } unless @user.full_name.present?
    missing_fields << { name: "Bio", field: :bio, path: edit_profile_path } unless @user.bio.present?
    missing_fields << { name: "Profile Picture", field: :avatar, path: edit_profile_path } unless @user.avatar.attached?
    missing_fields << { name: "GitHub URL", field: :github_url, path: edit_profile_path } unless @user.github_url.present?
    missing_fields << { name: "LinkedIn URL", field: :linkedin_url, path: edit_profile_path } unless @user.linkedin_url.present?
    missing_fields << { name: "Website URL", field: :website_url, path: edit_profile_path } unless @user.website_url.present?
    missing_fields << { name: "Job Title", field: :job_title, path: edit_profile_path } unless @user.job_title.present?
    missing_fields << { name: "Location", field: :location, path: edit_profile_path } unless @user.location.present?
    missing_fields << { name: "Headline", field: :headline, path: edit_profile_path } unless @user.headline.present?
    missing_fields << { name: "Contact Email", field: :contact_email, path: edit_profile_path } unless @user.contact_email.present?
    missing_fields << { name: "Skills", field: :skills, path: edit_profile_path } unless @user.skills.present? && @user.skills.any?

    missing_fields
  end
end
