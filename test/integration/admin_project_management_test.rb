require "test_helper"

class AdminProjectManagementTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email: "test_admin_int_#{SecureRandom.hex(3)}@example.com",
      password: "password123",
      username: "test_admin_int_#{SecureRandom.hex(3)}",
      role: :admin,
      account_status: :active
    )

    @regular_user = users(:test_user_one)
    @other_user = users(:test_user_two)

    # Create projects for different users
    @admin_project = @admin.projects.create!(
      title: "Admin's Project",
      description: "A project by admin",
      status: :published,
      technologies_used: ["Admin", "Rails"],
      display_order: 1
    )

    @user_project = @regular_user.projects.create!(
      title: "User's Project",
      description: "A project by regular user",
      status: :published,
      technologies_used: ["User", "Rails"],
      display_order: 1
    )

    @draft_project = @other_user.projects.create!(
      title: "Draft Project",
      description: "A draft project",
      status: :draft,
      technologies_used: ["Draft", "Rails"],
      display_order: 1
    )
  end

  test "admin can access all project management features" do
    sign_in @admin

    # Can view any project
    get project_path(@user_project)
    assert_response :success
    assert_select "h1", text: @user_project.title

    # Can edit any project
    get edit_project_path(@user_project)
    assert_response :success
    assert_select "h1", text: /edit.*project/i

    # Can update any project
    patch project_path(@user_project), params: {
      project: { title: "Admin Updated Title" }
    }
    assert_redirected_to project_path(@user_project)
    assert_equal "Project was successfully updated.", flash[:notice]

    @user_project.reload
    assert_equal "Admin Updated Title", @user_project.title
  end

  test "admin can manage projects from public view" do
    sign_in @admin

    # Can view public project page
    get public_project_path(@user_project)
    assert_response :success

    # Should see admin controls
    assert_select ".bg-orange-50", text: /admin controls/i
    assert_select "a[href='#{project_path(@user_project)}']", text: /edit project.*admin/i

    # Can edit from public view
    get project_path(@user_project)
    assert_response :success
  end

  test "admin can see project ownership information" do
    sign_in @admin

    get project_path(@user_project)
    assert_response :success

    # Should see admin controls with owner info
    assert_select "h4", text: /admin actions/i
    assert_select "a[href='#{public_profile_path(@regular_user.username)}']", text: /view owner profile/i
  end

  test "admin can access content moderation from project views" do
    sign_in @admin

    get project_path(@user_project)
    assert_response :success

    # Should see content moderation link
    assert_select "a[href='#{admin_content_moderation_projects_path}']", text: /content moderation/i
  end

  test "admin can delete any project" do
    sign_in @admin

    assert_difference("Project.count", -1) do
      delete project_path(@user_project)
    end

    assert_redirected_to projects_path
    assert_equal "Project was successfully deleted.", flash[:notice]
  end

  test "admin can view draft projects" do
    sign_in @admin

    get project_path(@draft_project)
    assert_response :success
    assert_select "h1", text: @draft_project.title
  end

  test "admin can edit draft projects" do
    sign_in @admin

    get edit_project_path(@draft_project)
    assert_response :success

    # Can publish draft project
    patch project_path(@draft_project), params: {
      project: { status: :published }
    }

    @draft_project.reload
    assert @draft_project.published?
  end

  test "admin sees admin indicator on public projects page" do
    sign_in @admin

    get public_projects_path
    assert_response :success

    # Should see admin indicator
    assert_select ".bg-orange-100.text-orange-800", text: /admin view/i
  end

  test "admin can access admin controls in public project view" do
    sign_in @admin

    get public_project_path(@user_project)
    assert_response :success

    # Should see admin controls section
    assert_select ".bg-orange-50", text: /admin controls/i

    # Should see project owner information
    assert_select "p", text: /project owner/i
    assert_select "p", text: /project status/i
    assert_select "p", text: /created/i
  end

  test "admin can manage projects across different users" do
    sign_in @admin

    # Can manage admin's own projects
    get project_path(@admin_project)
    assert_response :success

    # Can manage regular user's projects
    get project_path(@user_project)
    assert_response :success

    # Can manage other user's projects
    get project_path(@draft_project)
    assert_response :success
  end

  test "admin permissions work with super admin role" do
    super_admin = User.create!(
      email: "superadmin@example.com",
      password: "password123",
      username: "superadmin",
      role: :super_admin,
      account_status: :active
    )

    sign_in super_admin

    # Super admin should have same permissions as admin
    get project_path(@user_project)
    assert_response :success

    get edit_project_path(@user_project)
    assert_response :success

    patch project_path(@user_project), params: {
      project: { title: "Super Admin Updated" }
    }
    assert_redirected_to project_path(@user_project)
  end

  test "regular users cannot access admin features" do
    sign_in @regular_user

    # Cannot edit other user's projects
    get edit_project_path(@draft_project)
    assert_redirected_to projects_path
    assert_equal "You don't have permission to perform this action.", flash[:alert]

    # Cannot update other user's projects
    patch project_path(@draft_project), params: {
      project: { title: "Hacked Title" }
    }
    assert_redirected_to projects_path
    assert_equal "You don't have permission to perform this action.", flash[:alert]

    # Cannot delete other user's projects
    assert_no_difference("Project.count") do
      delete project_path(@draft_project)
    end
    assert_redirected_to projects_path
    assert_equal "You don't have permission to perform this action.", flash[:alert]
  end

  test "unauthenticated users cannot access admin features" do
    # Cannot edit projects
    get edit_project_path(@user_project)
    assert_redirected_to new_user_session_path

    # Cannot update projects
    patch project_path(@user_project), params: {
      project: { title: "Hacked Title" }
    }
    assert_redirected_to new_user_session_path

    # Cannot delete projects
    assert_no_difference("Project.count") do
      delete project_path(@user_project)
    end
    assert_redirected_to new_user_session_path
  end

  test "admin can access project management from navigation" do
    sign_in @admin

    # Should see admin link in navigation
    get root_path
    assert_response :success
    assert_select "a[href='#{admin_root_path}']", text: /admin/i
  end

  test "admin project management maintains data integrity" do
    sign_in @admin

    original_title = @user_project.title
    original_user = @user_project.user

    # Update project
    patch project_path(@user_project), params: {
      project: { title: "Updated by Admin" }
    }

    @user_project.reload
    assert_equal "Updated by Admin", @user_project.title
    assert_equal original_user, @user_project.user # Owner should remain the same
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
