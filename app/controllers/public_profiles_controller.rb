class PublicProfilesController < ApplicationController
  before_action :set_user

  # Display public user profile page that can be shared with visitors
  # Accessible at /:username (e.g., /gustavo)
  def show
    # If current user is viewing their own profile, redirect to authenticated profile
    if user_signed_in? && @user == current_user
      redirect_to profile_path
      return
    end

    # Only show published projects to public visitors
    @recent_projects = @user.projects.published.recent.limit(6)
  end

  private

  # Find user by username using FriendlyId
  # Returns 404 if user not found
  def set_user
    @user = User.friendly.find(params[:username])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end
end
