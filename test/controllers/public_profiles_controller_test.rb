require "test_helper"

class PublicProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user_one)
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
    @user.update!(account_status: :active)
    get public_profile_path(@user.username)
    assert_redirected_to profile_path
  end

  test "should show 404 for non-existent username" do
    get public_profile_path("nonexistent")
    assert_response :not_found
  end

  test "should only show published projects to public visitors" do
    # Create a published project
    published_project = projects(:test_project_one)
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

  test "should display share profile button with correct data attributes" do
    get public_profile_path(@user.username)
    assert_response :success

    # Should have share button with Stimulus controller
    assert_select "div[data-controller='share-button']"
    assert_select "button[data-action='click->share-button#share']", text: /share --profile/

    # Should have correct data attributes
    assert_select "div[data-share-button-title-value='#{@user.display_name}\\'s Profile']"
  end

  # Tests for deactivated account access control
  test "should show 404 for deactivated account when not signed in" do
    deactivated_user = users(:deactivated_user)
    get public_profile_path(deactivated_user.username)
    assert_response :not_found
  end

  test "should show 404 for deactivated account when signed in as different user" do
    deactivated_user = users(:deactivated_user)
    other_user = users(:test_user_two)
    other_user.update!(account_status: :active)

    sign_in other_user
    get public_profile_path(deactivated_user.username)
    assert_response :not_found
  end

  test "should allow deactivated account owner to view their own profile" do
    deactivated_user = users(:deactivated_user)
    sign_in deactivated_user
    get public_profile_path(deactivated_user.username), params: { preview: true }
    assert_response :success
    assert_select "h1", deactivated_user.display_name
  end

  test "should allow admin to view deactivated account" do
    deactivated_user = users(:deactivated_user)
    admin_user = users(:test_admin)
    admin_user.update!(account_status: :active)

    sign_in admin_user
    get public_profile_path(deactivated_user.username)
    assert_response :success
    assert_select "h1", deactivated_user.display_name
  end

  test "should allow super_admin to view deactivated account" do
    deactivated_user = users(:deactivated_user)
    super_admin = users(:test_admin)
    super_admin.update!(account_status: :active, role: :super_admin)

    sign_in super_admin
    get public_profile_path(deactivated_user.username)
    assert_response :success
    assert_select "h1", deactivated_user.display_name
  end

  test "should allow access to active accounts for all users" do
    active_user = users(:active_user)
    get public_profile_path(active_user.username)
    assert_response :success
    assert_select "h1", active_user.display_name
  end

  test "should allow access to pending activation accounts for all users" do
    pending_user = users(:pending_user)
    get public_profile_path(pending_user.username)
    assert_response :success
    assert_select "h1", pending_user.display_name
  end

  test "should allow access to suspended accounts for all users" do
    suspended_user = users(:suspended_user)
    get public_profile_path(suspended_user.username)
    assert_response :success
    assert_select "h1", suspended_user.display_name
  end
end
