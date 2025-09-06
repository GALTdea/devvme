require "test_helper"

class LimitedAccessControllerTest < ActionDispatch::IntegrationTest
  # Test pending_activation action
  test "should get pending_activation when user is pending" do
    sign_in users(:pending_user)
    get limited_access_pending_activation_url
    assert_response :success
  end

  # test "should redirect to dashboard when not signed in for pending_activation" do
  #   get limited_access_pending_activation_url
  #   assert_redirected_to dashboard_path
  # end

  # test "should redirect to dashboard when user is not pending for pending_activation" do
  #   sign_in users(:active_user)
  #   get limited_access_pending_activation_url
  #   assert_redirected_to dashboard_path
  # end

  # Test suspended action
  test "should get suspended when user is suspended" do
    skip "Skipping deactivated test"
    sign_in users(:suspended_user)
    get limited_access_suspended_url
    assert_response :success
  end

  # test "should redirect to dashboard when not signed in for suspended" do
  #   get limited_access_suspended_url
  #   assert_redirected_to dashboard_path
  # end

  # test "should redirect to dashboard when user is not suspended for suspended" do
  #   sign_in users(:active_user)
  #   get limited_access_suspended_url
  #   assert_redirected_to dashboard_path
  # end

  # Test deactivated action
  test "should get deactivated when user is deactivated" do
    skip "Skipping deactivated test"
    sign_in users(:deactivated_user)
    get limited_access_deactivated_url
    assert_response :success
  end

  # test "should redirect to dashboard when not signed in for deactivated" do
  #   get limited_access_deactivated_url
  #   assert_redirected_to dashboard_path
  # end

  # test "should redirect to dashboard when user is not deactivated for deactivated" do
  #   sign_in users(:active_user)
  #   get limited_access_deactivated_url
  #   assert_redirected_to dashboard_path
  # end
end
