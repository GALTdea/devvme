require "test_helper"

class Admin::BlogAnalyticsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_blog_analytics_index_url
    assert_response :success
  end
end
