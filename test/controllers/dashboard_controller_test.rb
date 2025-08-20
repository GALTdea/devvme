require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      username: "testuser",
      full_name: "Test User",
      bio: "I'm a test user"
    )
  end

  test "should redirect to sign in when not authenticated" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "should get index when authenticated" do
    sign_in @user
    get dashboard_path
    assert_response :success
  end

  test "should display user statistics" do
    sign_in @user

    # Create some projects for the user
    published_project = @user.projects.create!(
      title: "Published Project",
      description: "A published project",
      technologies: "Rails, Ruby",
      status: "published"
    )

    draft_project = @user.projects.create!(
      title: "Draft Project",
      description: "A draft project",
      technologies: "Rails, Ruby",
      status: "draft"
    )

    get dashboard_path
    assert_response :success

    # Should display projects count
    assert_select ".stats", text: /2.*Projects?/ # Total projects
    assert_select ".stats", text: /1.*Published/ # Published projects

    # Should display profile completion
    assert_select ".profile-completion"

    # Should display recent projects section
    assert_select ".recent-projects"
    assert_select ".project-card", text: /Published Project/
  end

  test "should display welcome message for new users" do
    new_user = User.create!(
      email: "newuser@example.com",
      password: "password123",
      username: "newuser"
    )

    sign_in new_user
    get dashboard_path
    assert_response :success

    # Should show welcome message or onboarding hints
    assert_select ".welcome, .getting-started"
  end

  test "should display profile completion percentage" do
    sign_in @user
    get dashboard_path
    assert_response :success

    # Should show profile completion
    completion_percentage = @user.profile_completion_percentage
    assert_select ".profile-completion", text: /#{completion_percentage}%/
  end

  test "should show recent projects in correct order" do
    sign_in @user

    # Create projects with different timestamps
    old_project = @user.projects.create!(
      title: "Old Project",
      description: "An old project",
      technologies: "Rails",
      status: "published",
      created_at: 2.days.ago
    )

    new_project = @user.projects.create!(
      title: "New Project",
      description: "A new project",
      technologies: "Rails",
      status: "published",
      created_at: 1.day.ago
    )

    get dashboard_path
    assert_response :success

    # New project should appear before old project
    response_body = response.body
    new_project_index = response_body.index("New Project")
    old_project_index = response_body.index("Old Project")

    assert_not_nil new_project_index
    assert_not_nil old_project_index
    assert new_project_index < old_project_index
  end

  test "should only display published projects in recent projects" do
    sign_in @user

    published_project = @user.projects.create!(
      title: "Published Project",
      description: "A published project",
      technologies: "Rails",
      status: "published"
    )

    draft_project = @user.projects.create!(
      title: "Draft Project",
      description: "A draft project",
      technologies: "Rails",
      status: "draft"
    )

    get dashboard_path
    assert_response :success

    # Should show published project
    assert_select ".recent-projects", text: /Published Project/

    # Should not show draft project
    assert_no_selector ".recent-projects", text: /Draft Project/
  end

  test "should limit recent projects to 3" do
    sign_in @user

    # Create 5 published projects
    5.times do |i|
      @user.projects.create!(
        title: "Project #{i + 1}",
        description: "Description #{i + 1}",
        technologies: "Rails",
        status: "published"
      )
    end

    get dashboard_path
    assert_response :success

    # Should only show 3 projects in recent section
    assert_select ".recent-projects .project-card", count: 3
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: user.password
      }
    }
  end
end
