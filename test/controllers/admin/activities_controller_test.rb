require "test_helper"

class Admin::ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:test_admin)
    sign_in @admin
  end

  test "should get index" do
    get admin_activities_url
    assert_response :success
  end

  test "should get show" do
    activity = admin_activities(:test_activity_one)
    get admin_activity_url(activity)
    assert_response :success
  end
end
