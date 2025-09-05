require "test_helper"

class Admin::BlogAnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:test_admin)
    sign_in @admin
  end

  test "should get index" do
    get admin_blog_analytics_index_url
    assert_response :success
  end
end
