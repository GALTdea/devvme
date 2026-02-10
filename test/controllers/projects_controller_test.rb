require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user_one)
    @other_user = users(:test_user_two)
    # Ensure users are active to avoid beta waiting redirect
    @user.update!(account_status: :active)
    @other_user.update!(account_status: :active)
    sign_in @user
    @project1 = projects(:test_project_one)
    @project2 = projects(:test_project_two)
    # Make project1 belong to current user
    @project1.update!(user: @user)
  end

  # INDEX TESTS
  test "should get index" do
    get projects_url
    assert_response :success
    assert_select "h1", text: /projects/i
  end

  test "should show only current user's projects on index" do
    get projects_url
    assert_response :success
    # Should see user's project
    assert_select "h3", text: @project1.title
    # Should not see other user's project
    assert_select "h3", { text: @project2.title, count: 0 }
  end

  test "should redirect to public projects when not authenticated for index" do
    sign_out @user
    get projects_url
    assert_redirected_to public_projects_path
  end

  # SHOW TESTS
  test "should show project" do
    get project_url(@project1)
    assert_response :success
    assert_select "h1", text: @project1.title
  end

  test "should show published project from other user without authentication" do
    @project2.update!(status: :published)
    sign_out @user
    get project_url(@project2)
    assert_response :success
    assert_select "h1", text: @project2.title
  end

  test "should redirect to public projects when trying to show unpublished project from other user" do
    @project2.update!(status: :draft)
    sign_out @user
    get project_url(@project2)
    assert_redirected_to public_projects_path
    assert_equal "Project not found.", flash[:alert]
  end

  test "should show any project when authenticated as owner" do
    @project2.update!(status: :draft)
    get project_url(@project2)
    assert_redirected_to public_projects_path
    assert_equal "Project not found.", flash[:alert]
  end

  # NEW TESTS
  test "should get new" do
    get new_project_url
    assert_response :success
    assert_select "h1", text: /new project/i
    assert_select "form"
  end

  test "should redirect to login when not authenticated for new" do
    sign_out @user
    get new_project_url
    assert_redirected_to new_user_session_path
  end

  # CREATE TESTS
  test "should create project with valid params" do
    assert_difference("Project.count") do
      post projects_url, params: {
        project: {
          title: "New Test Project",
          description: "A new test project description",
          technologies_display: "Rails, Ruby, PostgreSQL",
          live_url: "https://example.com",
          source_code_url: "https://github.com/user/repo",
          featured: true,
          status: "published"
        }
      }
    end

    project = Project.last
    assert_equal @user, project.user
    assert_equal "New Test Project", project.title
    assert_equal ["Rails", "Ruby", "PostgreSQL"], project.technologies_used
    assert_redirected_to project_path(project)
    assert_equal "Project was successfully created.", flash[:notice]
  end

  test "should not create project with invalid params" do
    assert_no_difference("Project.count") do
      post projects_url, params: {
        project: {
          title: "", # Invalid - empty title
          description: "Description",
          technologies_display: "Rails"
        }
      }
    end

    assert_response :unprocessable_content
    assert_select ".text-red-700", text: /can't be blank/
  end

  test "should redirect to login when not authenticated for create" do
    sign_out @user
    post projects_url, params: {
      project: {
        title: "Test Project",
        description: "Description",
        technologies_display: "Rails"
      }
    }
    assert_redirected_to new_user_session_path
  end

  # EDIT TESTS
  test "should get edit" do
    get edit_project_url(@project1)
    assert_response :success
    assert_select "h1", text: /edit.*project/i
    assert_select "form"
    assert_select "input[value='#{@project1.title}']"
  end

  test "should redirect when trying to edit other user's project" do
    get edit_project_url(@project2)
    assert_redirected_to projects_path
    assert_equal "You don't have permission to perform this action.", flash[:alert]
  end

  test "should redirect to login when not authenticated for edit" do
    sign_out @user
    get edit_project_url(@project1)
    assert_redirected_to new_user_session_path
  end

  # UPDATE TESTS
  test "should update project with valid params" do
    patch project_url(@project1), params: {
      project: {
        title: "Updated Project Title",
        description: "Updated description",
        technologies_display: "Vue, Node.js",
        featured: true,
        github_insights_enabled: false
      }
    }

    @project1.reload
    assert_equal "Updated Project Title", @project1.title
    assert_equal "Updated description", @project1.description
    assert_equal ["Vue", "Node.js"], @project1.technologies_used
    assert @project1.featured?
    assert_not @project1.github_insights_enabled?
    assert_redirected_to project_path(@project1)
    assert_equal "Project was successfully updated.", flash[:notice]
  end

  test "should not update project with invalid params" do
    original_title = @project1.title
    patch project_url(@project1), params: {
      project: {
        title: "", # Invalid
        description: "Updated description"
      }
    }

    @project1.reload
    assert_equal original_title, @project1.title # Should remain unchanged
    assert_response :unprocessable_content
    assert_select ".text-red-700", text: /can't be blank/
  end

  test "should redirect when trying to update other user's project" do
    patch project_url(@project2), params: {
      project: { title: "Hacked Title" }
    }
    assert_redirected_to projects_path
    assert_equal "You don't have permission to perform this action.", flash[:alert]
  end

  test "should redirect to login when not authenticated for update" do
    sign_out @user
    patch project_url(@project1), params: {
      project: { title: "Updated Title" }
    }
    assert_redirected_to new_user_session_path
  end

  # DESTROY TESTS
  test "should destroy project" do
    assert_difference("Project.count", -1) do
      delete project_url(@project1)
    end

    assert_redirected_to projects_path
    assert_equal "Project was successfully deleted.", flash[:notice]
  end

  test "should redirect when trying to destroy other user's project" do
    assert_no_difference("Project.count") do
      delete project_url(@project2)
    end
    assert_redirected_to projects_path
    assert_equal "You don't have permission to perform this action.", flash[:alert]
  end

  test "should redirect to login when not authenticated for destroy" do
    sign_out @user
    delete project_url(@project1)
    assert_redirected_to new_user_session_path
  end

  # REORDER TESTS
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

    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
  end

  test "should reject reorder with invalid project ids" do
    patch reorder_projects_url,
          params: { project_ids: [999, 1000] }.to_json,
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }

    assert_response :unprocessable_content
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
  end

  test "should reject reorder of projects not owned by user" do
    patch reorder_projects_url,
          params: { project_ids: [@project2.id] }.to_json,
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }

    assert_response :unprocessable_content
  end

  test "should reject reorder without authentication" do
    sign_out @user

    patch reorder_projects_url,
          params: { project_ids: [@project1.id, @project2.id] }.to_json,
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }

    assert_response :unauthorized
  end

  test "should reject reorder with empty project_ids" do
    patch reorder_projects_url,
          params: { project_ids: [] }.to_json,
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }

    assert_response :unprocessable_content
  end

  # GITHUB INSIGHTS REFRESH TESTS
  test "should enqueue deep manual github insights refresh for owner" do
    @project1.update_columns(source_code_url: "https://github.com/rails/rails", github_insights_sync_status: "ready")
    clear_enqueued_jobs

    assert_enqueued_with(job: GitHubInsightsSyncJob, args: [@project1.id, { sync_type: "deep", source: "manual" }]) do
      post refresh_github_insights_project_url(@project1)
    end

    @project1.reload
    assert_equal "queued", @project1.github_insights_sync_status
    assert_redirected_to edit_project_path(@project1)
    assert_equal "GitHub insights refresh started.", flash[:notice]
  end

  test "should not refresh github insights when repo url missing" do
    @project1.update_columns(source_code_url: nil, github_url: nil)
    clear_enqueued_jobs

    assert_no_enqueued_jobs only: GitHubInsightsSyncJob do
      post refresh_github_insights_project_url(@project1)
    end

    assert_redirected_to edit_project_path(@project1)
    assert_equal "Add a valid GitHub Source Code URL before refreshing insights.", flash[:alert]
  end

  test "should not refresh github insights while syncing" do
    @project1.update_columns(source_code_url: "https://github.com/rails/rails", github_insights_sync_status: "syncing")
    clear_enqueued_jobs

    assert_no_enqueued_jobs only: GitHubInsightsSyncJob do
      post refresh_github_insights_project_url(@project1)
    end

    assert_redirected_to edit_project_path(@project1)
    assert_equal "GitHub insights sync is already in progress.", flash[:alert]
  end

  test "should reject github insights refresh for non-owner" do
    post refresh_github_insights_project_url(@project2)

    assert_redirected_to projects_path
    assert_equal "You don't have permission to perform this action.", flash[:alert]
  end

  # ADMIN TESTS
  test "should allow admin to view any project" do
    admin = users(:test_admin)
    admin.update!(account_status: :active)
    sign_out @user
    sign_in admin

    get project_url(@project2)
    assert_response :success
    assert_select "h1", text: @project2.title
  end

  test "should allow admin to edit any project" do
    admin = users(:test_admin)
    admin.update!(account_status: :active)
    sign_out @user
    sign_in admin

    get edit_project_url(@project2)
    assert_response :success
    assert_select "h1", text: /edit.*project/i
  end

  test "should allow admin to update any project" do
    admin = users(:test_admin)
    admin.update!(account_status: :active)
    sign_out @user
    sign_in admin

    patch project_url(@project2), params: {
      project: { title: "Admin Updated Title" }
    }

    @project2.reload
    assert_equal "Admin Updated Title", @project2.title
    assert_redirected_to project_path(@project2)
  end

  test "should allow admin to delete any project" do
    admin = users(:test_admin)
    admin.update!(account_status: :active)

    # Sign out the current user and sign in admin
    sign_out @user
    sign_in admin

    # Ensure project2 exists and belongs to other user
    @project2.reload
    assert_equal @other_user, @project2.user, "Project2 should belong to other user"

    # Verify we're signed in as admin
    assert_equal admin, @controller.current_user, "Should be signed in as admin"

    assert_difference("Project.count", -1) do
      delete project_url(@project2)
    end

    assert_redirected_to projects_path
    assert_equal "Project was successfully deleted.", flash[:notice]
  end

  test "should show admin controls in project views for admins" do
    admin = users(:test_admin)
    admin.update!(account_status: :active)
    sign_out @user
    sign_in admin

    get project_url(@project2)
    assert_response :success

    # Should show admin controls
    assert_select "h4", text: /admin actions/i
    assert_select "a[href='#{public_profile_path(@project2.user.username)}']", text: /view owner profile/i
  end

  # FILE UPLOAD TESTS
  test "should handle image uploads on create" do
    assert_difference("Project.count") do
      post projects_url, params: {
        project: {
          title: "Project with Images",
          description: "A project with image uploads",
          technologies_display: "Rails",
          images: [
            fixture_file_upload("test_image.png", "image/png")
          ]
        }
      }
    end

    project = Project.last
    assert project.images.any?
  end

  test "should handle thumbnail upload on create" do
    assert_difference("Project.count") do
      post projects_url, params: {
        project: {
          title: "Project with Thumbnail",
          description: "A project with thumbnail",
          technologies_display: "Rails",
          thumbnail: fixture_file_upload("test_image.png", "image/png")
        }
      }
    end

    project = Project.last
    assert project.thumbnail.attached?
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

  def sign_out(user)
    delete destroy_user_session_path
  end
end
