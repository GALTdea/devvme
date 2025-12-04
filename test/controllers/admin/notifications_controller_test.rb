require "test_helper"

class Admin::NotificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:test_admin)
    @new_user = User.create!(
      username: "testuser",
      email: "testuser@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    # Create a notification for the admin and get the database record
    NewUserSignupNotification.with(user: @new_user).deliver(@admin)
    @notification = @admin.notifications.last
  end

  test "should get index" do
    sign_in @admin
    get admin_notifications_path
    assert_response :success
  end

  test "should show notifications for admin" do
    sign_in @admin
    get admin_notifications_path
    assert_response :success
    assert_select "h3", text: /Notifications/
  end

  test "should mark notification as read" do
    sign_in @admin
    assert @notification.unread?

    patch mark_as_read_admin_notification_path(@notification)
    assert_redirected_to admin_notifications_path

    @notification.reload
    assert @notification.read?
  end

  test "should mark all notifications as read" do
    sign_in @admin
    # Create another notification
    another_user = User.create!(
      username: "anotheruser",
      email: "another@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    NewUserSignupNotification.with(user: another_user).deliver(@admin)

    assert_equal 2, @admin.notifications.unread.count

    patch mark_all_as_read_admin_notifications_path
    assert_redirected_to admin_notifications_path

    assert_equal 0, @admin.notifications.unread.count
  end

  test "should require admin access" do
    regular_user = users(:test_user_one)
    sign_in regular_user
    get admin_notifications_path
    assert_redirected_to root_path
  end
end
