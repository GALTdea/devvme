require "test_helper"

class PublicProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should show public profile by username" do
    get public_profile_path(@user.username)
    assert_response :success
    assert_select "h1", @user.display_name
    assert_select "p", text: /@#{@user.username}/
  end

  test "should show public profile by friendly_id slug" do
    get "/#{@user.friendly_id}"
    assert_response :success
    assert_select "h1", @user.display_name
  end

  test "should redirect authenticated user viewing their own public profile" do
    sign_in @user
    get public_profile_path(@user.username)
    assert_redirected_to profile_path
  end

  test "should show 404 for non-existent username" do
    get public_profile_path("nonexistent")
    assert_response :not_found
  end

  test "should only show published projects to public visitors" do
    # Create a published project
    published_project = projects(:one)
    published_project.update!(status: :published, user: @user)

    # Create a draft project
    draft_project = @user.projects.create!(
      title: "Draft Project",
      description: "This is a draft",
      status: :draft,
      technologies_used: ["Ruby", "Rails"],
      display_order: 2
    )

    get public_profile_path(@user.username)
    assert_response :success

    # Should show published project
    assert_select "h3", text: published_project.title

    # Should not show draft project
    assert_select "h3", text: draft_project.title, count: 0
  end
end
