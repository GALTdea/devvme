class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    if current_user == @user
      return redirect_back fallback_location: public_profile_path(@user.username), alert: "You cannot follow yourself."
    end

    unless @user.can_be_followed?
      return redirect_back fallback_location: public_profile_path(@user.username), alert: "This user cannot be followed."
    end

    current_user.follow!(@user)

    respond_to do |format|
      format.turbo_stream { render "follows/update_button", locals: { user: @user } }
      format.html { redirect_back fallback_location: public_profile_path(@user.username), notice: "You are now following this user." }
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: public_profile_path(@user.username), alert: e.record.errors.full_messages.to_sentence
  end

  def destroy
    current_user.unfollow!(@user)

    respond_to do |format|
      format.turbo_stream { render "follows/update_button", locals: { user: @user } }
      format.html { redirect_back fallback_location: public_profile_path(@user.username), notice: "You unfollowed this user." }
    end
  end

  private

  def set_user
    @user = User.friendly.find(params[:username])
  rescue ActiveRecord::RecordNotFound
    redirect_back fallback_location: root_path, alert: "User not found"
  end
end
