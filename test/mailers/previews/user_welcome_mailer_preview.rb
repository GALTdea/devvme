# Preview all emails at http://localhost:3000/rails/mailers
class UserWelcomeMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_welcome_mailer_preview/welcome_notification
  def welcome_notification
    # Create a mock user for preview
    user = OpenStruct.new(
      email: "john.doe@example.com",
      display_name: "John Doe",
      username: "johndoe"
    )

    UserWelcomeMailer.welcome_notification(user)
  end

  # Preview with different user data
  def welcome_notification_different_user
    user = OpenStruct.new(
      email: "jane.smith@example.com",
      display_name: "Jane Smith",
      username: "janesmith"
    )

    UserWelcomeMailer.welcome_notification(user)
  end
end
