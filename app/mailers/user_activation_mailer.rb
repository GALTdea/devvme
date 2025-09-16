class UserActivationMailer < ApplicationMailer
  layout false # Disable layout since our template is self-contained

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_activation_mailer.activation_notification.subject
  #
  def activation_notification(user)
    @user = user
    @login_url = new_user_session_url

    mail(
      to: @user.email,
      subject: "🎉 Your Devv.me account is now active!"
    )
  end
end
