require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @project1 = projects(:one)
    @project2 = projects(:two)
  end

  test "should get index" do
    get projects_url
    assert_response :success
  end

  test "should reorder projects successfully" do
    # Ensure projects belong to the signed-in user with valid data
    @project1.update!(user: @user, display_order: 1, technologies_used: ["Ruby", "Rails"])
    @project2.update!(user: @user, display_order: 2, technologies_used: ["JavaScript", "React"])

    # Test reordering
    patch reorder_projects_url,
          params: { project_ids: [@project2.id, @project1.id] }.to_json,
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }

    assert_response :success

    # Verify the order was updated
    @project1.reload
    @project2.reload

    assert_equal 2, @project1.display_order
    assert_equal 1, @project2.display_order
  end

  test "should reject reorder with invalid project ids" do
    patch reorder_projects_url,
          params: { project_ids: [999, 1000] }.to_json,
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }

    assert_response :unprocessable_entity
  end

  test "should reject reorder without authentication" do
    sign_out @user

    patch reorder_projects_url,
          params: { project_ids: [@project1.id, @project2.id] }.to_json,
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }

    assert_response :unauthorized
  end
end
