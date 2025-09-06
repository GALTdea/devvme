require "test_helper"

class LimitedAccessControllerTest < ActionDispatch::IntegrationTest
  test "should get pending_activation" do
    get limited_access_pending_activation_url
    assert_response :success
  end

  test "should get suspended" do
    get limited_access_suspended_url
    assert_response :success
  end

  test "should get deactivated" do
    get limited_access_deactivated_url
    assert_response :success
  end
end
