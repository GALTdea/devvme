require "test_helper"

class NewUserSignupNotificationTest < ActiveSupport::TestCase
  def setup
    @admin = users(:test_admin)
    @new_user = User.create!(
      username: "newuser",
      email: "newuser@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "creates notification for admin when new user signs up" do
    assert_difference -> { @admin.notifications.count }, 1 do
      NewUserSignupNotification.with(user: @new_user).deliver(@admin)
    end
  end

  test "notification contains correct user information" do
    notification_event = NewUserSignupNotification.with(user: @new_user).deliver(@admin)

    # The .deliver() returns the event instance, which has direct access to params, title, message
    assert_equal @new_user, notification_event.params[:user]
    assert_equal "New User Signup: #{@new_user.username}", notification_event.title
    assert_match @new_user.username, notification_event.message
    assert_match @new_user.email, notification_event.message
  end

  test "notification is unread by default" do
    NewUserSignupNotification.with(user: @new_user).deliver(@admin)

    # Get the actual database record
    notification_record = @admin.notifications.last

    assert notification_record.read_at.nil?
    assert notification_record.unread?
    assert @admin.notifications.unread.include?(notification_record)
  end

  test "notification can be marked as read" do
    NewUserSignupNotification.with(user: @new_user).deliver(@admin)

    # Get the actual database record
    notification_record = @admin.notifications.last

    assert notification_record.unread?
    notification_record.mark_as_read!
    notification_record.reload
    assert notification_record.read?
    assert_not @admin.notifications.unread.include?(notification_record)
  end
end
