require "test_helper"

class Admin::VisitorAnalyticsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_visitor_analytics_index_url
    assert_response :success
  end
end
