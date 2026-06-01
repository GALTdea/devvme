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
    assert_select "div", text: /2/ # Total projects
    assert_select "div", text: /1/ # Published projects

    # Should display profile completion
    assert_select "div", text: /#{@user.profile_completion_percentage}%/

    # Should display recent projects section
    assert_select "h2", text: /Recent Project Stories/
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
    assert_select "h2", text: /Turn your work into proof/
    assert_select "a", text: /Create your first project story/
  end

  test "should show proof of work guidance for projects needing story context" do
    sign_in @user

    @user.projects.create!(
      title: "Weak Project",
      description: "A project without story fields",
      technologies_used: [ "Rails" ],
      status: "draft"
    )

    get dashboard_path
    assert_response :success

    assert_select "p", text: /Next proof-of-work step/
    assert_select "a", text: /Add story context/
  end

  test "should show share project story guidance when one published story exists" do
    sign_in @user

    @user.projects.create!(
      title: "Ready Story",
      description: "Published proof-of-work story",
      technologies_used: [ "Rails" ],
      status: "published",
      project_story: {
        overview: "What I built",
        problem: "Why it mattered",
        role: "What I owned"
      }
    )

    get dashboard_path
    assert_response :success

    assert_select "a", text: /Share your project story/
  end

  test "should show share profile guidance when multiple published stories exist" do
    sign_in @user

    2.times do |index|
      @user.projects.create!(
        title: "Published Story #{index + 1}",
        description: "Published proof-of-work story #{index + 1}",
        technologies_used: [ "Rails" ],
        status: "published",
        display_order: index + 10,
        project_story: {
          overview: "Overview #{index + 1}",
          problem: "Problem #{index + 1}",
          role: "Role #{index + 1}"
        }
      )
    end

    get dashboard_path
    assert_response :success

    assert_select "a", text: /Share your proof-of-work profile/
  end

  test "should display profile completion percentage" do
    sign_in @user
    get dashboard_path
    assert_response :success

    # Should show profile completion
    completion_percentage = @user.profile_completion_percentage
    assert_select "div", text: /#{completion_percentage}%/
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
    assert_select "h2", text: /Recent Project Stories/
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
    # Check that we have exactly 3 project title links in the recent projects section
    assert_select "h2", text: /Recent Project Stories/
    # Count project title links (not edit links or new project links)
    project_title_links = css_select("h3 a").select { |link| link.text.strip.match?(/Project \d+/) }
    assert_equal 3, project_title_links.length
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
