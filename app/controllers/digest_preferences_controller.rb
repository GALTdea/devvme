class DigestPreferencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_digest_preference

  def show
    # Show current digest preferences
  end

  def update
    if @digest_preference.update(digest_preference_params)
      redirect_to digest_preferences_path, notice: "Digest preferences updated successfully!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  def unsubscribe
    # Handle unsubscribe from email links
    token = params[:token]

    if token.present?
      begin
        user_id = Rails.application.message_verifier("digest_unsubscribe").verify(token)
        user = User.find(user_id)

        if user_signed_in? && current_user == user
          user.digest_preference_or_create.disable_digests!
          redirect_to digest_preferences_path, notice: "You have been unsubscribed from digest emails."
        else
          redirect_to root_path, notice: "Please sign in to manage your digest preferences."
        end
      rescue => e
        Rails.logger.error "Invalid unsubscribe token: #{e.message}"
        redirect_to root_path, alert: "Invalid unsubscribe link."
      end
    else
      redirect_to root_path, alert: "Invalid unsubscribe link."
    end
  end

  private

  def set_digest_preference
    @digest_preference = current_user.digest_preference_or_create
  end

  def digest_preference_params
    params.require(:user_digest_preference).permit(
      :frequency,
      :enabled,
      :include_blog_posts,
      :include_projects,
      :include_profile_updates,
      :digest_time,
      :timezone
    )
  end
end
