require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:test_admin)
    sign_in @admin
  end

  test "should get index" do
    get admin_users_url
    assert_response :success
  end

  test "should get show" do
    user = users(:test_user_one)
    get admin_user_url(user)
    assert_response :success
  end

  test "should get edit" do
    user = users(:test_user_one)
    get edit_admin_user_url(user)
    assert_response :success
  end

  test "should get update" do
    user = users(:test_user_one)
    patch admin_user_url(user), params: { user: { full_name: "Updated Name" } }
    assert_response :redirect
  end

  test "should get destroy" do
    user = users(:test_user_one)
    delete admin_user_url(user)
    assert_response :redirect
  end

  test "should get bulk_suspend" do
    skip "Feature not yet implemented - would test bulk suspend functionality"
    # post admin_users_bulk_suspend_url, params: { user_ids: [users(:test_user_one).id] }
    # assert_response :redirect
  end

  test "should get bulk_delete" do
    skip "Feature not yet implemented - would test bulk delete functionality"
    # get admin_users_bulk_delete_url
    # assert_response :success
  end
end
