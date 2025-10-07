class FollowingController < ApplicationController
  before_action :set_user

  def index
    # Get following with basic pagination
    per_page = 20
    page = (params[:page] || 1).to_i
    offset = (page - 1) * per_page

    if user_signed_in? && current_user == @user
      # For own profile, show all following
      @following = @user.following
                        .includes(:avatar_attachment)
                        .order(created_at: :desc)
                        .limit(per_page)
                        .offset(offset)
      @total_count = @user.following.count
    else
      # For public view, only show active/invited users
      @following = @user.following
                        .where(account_status: [:active, :invited])
                        .includes(:avatar_attachment)
                        .order(created_at: :desc)
                        .limit(per_page)
                        .offset(offset)
      @total_count = @user.following.where(account_status: [:active, :invited]).count
    end

    @current_page = page
    @total_pages = (@total_count.to_f / per_page).ceil
  end

  private

  def set_user
    @user = User.friendly.find(params[:username])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "User not found"
  end
end
