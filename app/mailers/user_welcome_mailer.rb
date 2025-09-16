class UserWelcomeMailer < ApplicationMailer
  layout false # Disable layout since our template is self-contained

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_welcome_mailer.welcome_notification.subject
  #
  def welcome_notification(user)
    @user = user
    @dashboard_url = dashboard_url
    @profile_url = public_profile_url(@user.username)

    mail(
      to: @user.email,
      subject: I18n.t("user_welcome_mailer.welcome_notification.subject")
    )
  end
end
