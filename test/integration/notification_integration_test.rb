require "test_helper"

class NotificationIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:test_admin)
    @user_attributes = {
      email: "newuser@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "newuser"
    }
  end

  test "notifies admins when user signs up" do
    sign_in @admin

    # Get initial notification count
    initial_count = @admin.notifications.count

    # Sign out admin to simulate new user registration
    sign_out @admin

    # Create a new user (simulating registration)
    post user_registration_path, params: { user: @user_attributes }

    # Sign back in as admin
    sign_in @admin

    # Check that admin received a notification
    @admin.reload
    assert_equal initial_count + 1, @admin.notifications.count

    # Verify notification content
    notification = @admin.notifications.order(created_at: :desc).first
    assert_equal "NewUserSignupNotification::Notification", notification.type
    assert notification.unread?
  end

  test "notification appears in admin dashboard" do
    # Create a notification first
    new_user = User.create!(@user_attributes)
    NewUserSignupNotification.with(user: new_user).deliver(@admin)

    sign_in @admin
    get admin_root_path
    assert_response :success

    # Check that notifications section is present
    assert_select "h3", text: /Notifications/
    assert_select "#notification_#{@admin.notifications.first.id}"
  end

  test "notification appears in notifications index" do
    # Create a notification first
    new_user = User.create!(@user_attributes)
    notification = NewUserSignupNotification.with(user: new_user).deliver(@admin)

    sign_in @admin
    get admin_notifications_path
    assert_response :success

    # Check that notification is displayed
    assert_select "#notification_#{notification.id}"
    assert_select "p", text: /New User Signup/
  end
end
