# Preview all emails at http://localhost:3000/rails/mailers/user_activation_mailer
class UserActivationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_activation_mailer/activation_notification
  def activation_notification
    UserActivationMailer.activation_notification
  end
end
