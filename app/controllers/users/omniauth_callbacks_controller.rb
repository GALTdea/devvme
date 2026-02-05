# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    auth = request.env["omniauth.auth"]
    auth_data = auth.respond_to?(:to_h) ? auth.to_h : auth
    existing_user = find_existing_user(auth_data)
    if existing_user.blank? && ENV["DISABLE_REGISTRATION"].present?
      redirect_to new_user_session_path, alert: "New registrations are currently disabled."
      return
    end

    user = User.from_omniauth(auth)

    if user.persisted?
      sign_in user
      redirect_to after_sign_in_path_for(user), notice: t("devise.omniauth_callbacks.success", kind: "GitHub")
      return
    end

    redirect_to new_user_session_path, alert: "GitHub sign-in failed. Please try again."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_user_session_path, alert: "GitHub sign-in failed: #{e.record.errors.full_messages.to_sentence}"
  end

  def failure
    redirect_to new_user_session_path, alert: "Could not authenticate with GitHub."
  end

  private

  def find_existing_user(auth_data)
    provider = auth_data["provider"].to_s
    uid = auth_data["uid"].to_s
    email = auth_data.dig("info", "email").to_s.downcase.presence
    User.find_by(provider: provider, uid: uid) || (email.present? ? User.find_by(email: email) : nil)
  end
end
