class UserInvitationMailer < ApplicationMailer
  layout false # Disable layout since our template is self-contained

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_invitation_mailer.invitation_notification.subject
  #
  def invitation_notification(user, admin = nil)
    @user = user
    @admin = admin
    @profile_url = "#{Rails.application.config.action_mailer.default_url_options[:host]}/#{@user.username}"
    @claim_url = "#{Rails.application.config.action_mailer.default_url_options[:host]}/invitations/#{@user.invitation_token}/claim"
    @admin_name = @admin&.display_name || "Devv.me Team"

    mail(
      to: @user.email,
      subject: "🚀 You've been invited to join Devv.me - Your profile is ready!"
    )
  end
end
