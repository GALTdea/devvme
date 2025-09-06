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
    # Update account status after creation to override the pending_activation callback
    @user.update!(account_status: :active)
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
      technologies_used: ["Rails", "Ruby"],
      status: "published"
    )

    draft_project = @user.projects.create!(
      title: "Draft Project",
      description: "A draft project",
      technologies_used: ["Rails", "Ruby"],
      status: "draft"
    )

    get dashboard_path
    assert_response :success

    # Should display projects count
    assert_select "dd", text: /2/ # Total projects
    assert_select "dd", text: /1/ # Published projects

    # Should display profile completion
    assert_select "dd", text: /#{@user.profile_completion_percentage}%/

    # Should display recent projects section
    assert_select "h2", text: /Recent Projects/
    assert_select "h3", text: /Published Project/
  end

  test "should display welcome message for new users" do
    new_user = User.create!(
      email: "newuser@example.com",
      password: "password123",
      username: "newuser"
    )
    # Update account status after creation to override the pending_activation callback
    new_user.update!(account_status: :active)

    sign_in new_user
    get dashboard_path
    assert_response :success

    # Should show welcome message
    assert_select "h1", text: /Welcome back/
  end

  test "should display profile completion percentage" do
    sign_in @user
    get dashboard_path
    assert_response :success

    # Should show profile completion
    completion_percentage = @user.profile_completion_percentage
    assert_select "dd", text: /#{completion_percentage}%/
  end

  test "should show recent projects in correct order" do
    sign_in @user

    # Create projects with different timestamps
    old_project = @user.projects.create!(
      title: "Old Project",
      description: "An old project",
      technologies_used: ["Rails"],
      status: "published",
      created_at: 2.days.ago
    )

    new_project = @user.projects.create!(
      title: "New Project",
      description: "A new project",
      technologies_used: ["Rails"],
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
      technologies_used: ["Rails"],
      status: "published"
    )

    draft_project = @user.projects.create!(
      title: "Draft Project",
      description: "A draft project",
      technologies_used: ["Rails"],
      status: "draft"
    )

    get dashboard_path
    assert_response :success

    # Should show published project
    assert_select "h2", text: /Recent Projects/
    assert_select "h3", text: /Published Project/

    # Should not show draft project
    assert_select "h3", text: /Draft Project/, count: 0
  end

  test "should limit recent projects to 3" do
    sign_in @user

    # Create 5 published projects
    5.times do |i|
      @user.projects.create!(
        title: "Project #{i + 1}",
        description: "Description #{i + 1}",
        technologies_used: ["Rails"],
        status: "published"
      )
    end

    get dashboard_path
    assert_response :success

    # Should only show 3 projects in recent section
    # Find the Recent Projects section and count projects within it
    recent_section = css_select("div.mb-8").find { |div| div.text.include?("Recent Projects") }
    project_cards_in_recent = recent_section.css(".bg-white")
    assert_equal 3, project_cards_in_recent.length
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
