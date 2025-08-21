class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  # Display user profile page (authenticated user's own profile)
  def show
    # Set the public profile URL for sharing
    @public_profile_url = public_profile_url(@user.friendly_id)
  end

  # Show profile edit form
  def edit
  end

  # Update user profile with validation and proper error handling
  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully!"
    else
      # Re-render edit form with validation errors
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Set current user for all profile actions
  def set_user
    @user = current_user
  end

  # Strong parameters for profile updates
  # Only allows specific profile fields to be updated
  def profile_params
    params.require(:user).permit(:username, :full_name, :bio, :github_url, :linkedin_url, :website_url, :avatar)
  end
end
