require "test_helper"

class Admin::VisitorAnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:test_admin)
    sign_in @admin_user
  end

  test "should get index for admin users" do
    get admin_visitor_analytics_index_url
    assert_response :success
    assert_select "h1", "Visitor Analytics"
  end

  test "should return JSON data for AJAX requests" do
    get admin_visitor_analytics_index_url, headers: { "Accept" => "application/json" }
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response.key?("unique_visitors")
    assert json_response.key?("total_visitors")
    assert json_response.key?("conversion_rate")
    assert json_response.key?("returning_visitors")
  end

  test "should redirect non-admin users" do
    sign_out @admin_user
    regular_user = users(:test_user_one)

    sign_in regular_user

    get admin_visitor_analytics_index_url
    assert_redirected_to root_path
  end

  test "should handle time range parameter" do
    get admin_visitor_analytics_index_url, params: { time_range: "7_days" }
    assert_response :success
  end
end
