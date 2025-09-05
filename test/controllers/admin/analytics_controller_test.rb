require "test_helper"

class Admin::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:test_admin)
    sign_in @admin_user
  end

  test "should get index" do
    get admin_analytics_index_url
    assert_response :success
  end

  test "should get registration_trends" do
    get admin_analytics_registration_trends_url
    assert_response :success
  end

  test "should get user_engagement" do
    get admin_analytics_user_engagement_url
    assert_response :success
  end

  test "should redirect non-admin users" do
    sign_out @admin_user
    @regular_user = users(:one)
    sign_in @regular_user

    get admin_analytics_index_url
    assert_redirected_to root_path
  end
end
