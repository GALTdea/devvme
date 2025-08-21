require "test_helper"

class ProjectsManagementTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    sign_in_as(@user)
  end

  test "user can manage multiple projects with different statuses" do
    # Create projects with different statuses
    draft_project = @user.projects.create!(
      title: "Draft Project",
      description: "A draft project",
      technologies_used: ["Rails"],
      status: "draft"
    )

    published_project = @user.projects.create!(
      title: "Published Project",
      description: "A published project",
      technologies_used: ["Vue"],
      status: "published"
    )

    archived_project = @user.projects.create!(
      title: "Archived Project",
      description: "An archived project",
      technologies_used: ["React"],
      status: "archived"
    )

    get projects_path
    assert_response :success

    # Should see all projects regardless of status on index
    assert_select "h3", text: "Draft Project"
    assert_select "h3", text: "Published Project"
    assert_select "h3", text: "Archived Project"
  end

  test "user can reorder multiple projects" do
    # Create multiple projects
    project1 = @user.projects.create!(
      title: "First Project",
      description: "Description 1",
      technologies_used: ["Rails"],
      display_order: 1
    )

    project2 = @user.projects.create!(
      title: "Second Project",
      description: "Description 2",
      technologies_used: ["Vue"],
      display_order: 2
    )

    project3 = @user.projects.create!(
      title: "Third Project",
      description: "Description 3",
      technologies_used: ["React"],
      display_order: 3
    )

    # Test reordering via AJAX
    new_order = [project3.id, project1.id, project2.id]

    patch reorder_projects_path,
          params: { project_ids: new_order }.to_json,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]

    # Verify the new order
    project1.reload
    project2.reload
    project3.reload

    assert_equal 2, project1.display_order
    assert_equal 3, project2.display_order
    assert_equal 1, project3.display_order
  end

  test "edge case: user cannot reorder with invalid project IDs" do
    patch reorder_projects_path,
          params: { project_ids: [999, 1000, 1001] }.to_json,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }

    assert_response :unprocessable_content
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
  end

  test "edge case: user cannot reorder other user's projects" do
    other_project = @other_user.projects.create!(
      title: "Other User Project",
      description: "Not my project",
      technologies_used: ["Rails"]
    )

    patch reorder_projects_path,
          params: { project_ids: [other_project.id] }.to_json,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }

    assert_response :unprocessable_content
  end

  test "user can create project with maximum technologies" do
    max_technologies = (1..10).map { |i| "Tech#{i}" }

    post projects_path, params: {
      project: {
        title: "Max Tech Project",
        description: "Project with maximum technologies",
        technologies_display: max_technologies.join(", "),
        status: "published"
      }
    }

    assert_response :redirect
    project = Project.last
    assert_equal 10, project.technologies_used.length
    assert_equal max_technologies, project.technologies_used
  end

  test "edge case: user cannot create project with too many technologies" do
    too_many_technologies = (1..15).map { |i| "Tech#{i}" }

    post projects_path, params: {
      project: {
        title: "Too Many Tech Project",
        description: "Project with too many technologies",
        technologies_display: too_many_technologies.join(", ")
      }
    }

    assert_response :unprocessable_content
    assert_select ".text-red-700", text: /too many technologies/
  end

  test "edge case: user cannot create project with technology names too long" do
    long_tech = "a" * 60 # Longer than 50 character limit

    post projects_path, params: {
      project: {
        title: "Long Tech Project",
        description: "Project with long technology name",
        technologies_display: long_tech
      }
    }

    assert_response :unprocessable_content
    assert_select ".text-red-700", text: /too long/
  end

  test "URL normalization works during creation" do
    post projects_path, params: {
      project: {
        title: "URL Test Project",
        description: "Testing URL normalization",
        technologies_display: "Rails",
        live_url: "example.com", # Missing https://
        source_code_url: "github.com/user/repo" # Missing https://
      }
    }

    assert_response :redirect
    project = Project.last
    assert_equal "https://example.com", project.live_url
    assert_equal "https://github.com/user/repo", project.source_code_url
  end

  test "edge case: user cannot create project with invalid URLs" do
    post projects_path, params: {
      project: {
        title: "Invalid URL Project",
        description: "Project with invalid URLs",
        technologies_display: "Rails",
        live_url: "not-a-url",
        source_code_url: "javascript:alert('xss')"
      }
    }

    assert_response :unprocessable_content
    assert_select ".text-red-700", text: /must be a valid URL/
  end

  test "featured projects can be managed correctly" do
    # Create regular and featured projects
    regular_project = @user.projects.create!(
      title: "Regular Project",
      description: "Not featured",
      technologies_used: ["Rails"],
      featured: false
    )

    featured_project = @user.projects.create!(
      title: "Featured Project",
      description: "This is featured",
      technologies_used: ["Vue"],
      featured: true
    )

    get projects_path
    assert_response :success

    # Both should appear in user's project list
    assert_select "h3", text: "Regular Project"
    assert_select "h3", text: "Featured Project"
  end

  test "large batch operations work correctly" do
    # Create 20 projects to test performance
    projects = []
    20.times do |i|
      projects << @user.projects.create!(
        title: "Batch Project #{i + 1}",
        description: "Batch project description #{i + 1}",
        technologies_used: ["Rails", "Ruby"],
        display_order: i + 1
      )
    end

    get projects_path
    assert_response :success

    # Should display all projects
    projects.each do |project|
      assert_select "h3", text: project.title
    end

    # Test reordering the first 5 projects
    first_five = projects.first(5)
    reversed_order = first_five.reverse.map(&:id)

    patch reorder_projects_path,
          params: { project_ids: reversed_order }.to_json,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }

    assert_response :success

    # Verify reordering worked
    first_five.each_with_index do |project, index|
      project.reload
      expected_order = first_five.length - index
      assert_equal expected_order, project.display_order
    end
  end

  test "concurrent project operations are handled safely" do
    project = @user.projects.create!(
      title: "Concurrent Test Project",
      description: "Testing concurrent operations",
      technologies_used: ["Rails"]
    )

    # Simulate concurrent updates
    original_title = project.title

    # First update
    patch project_path(project), params: {
      project: { title: "Updated Title 1" }
    }
    assert_response :redirect

    # Reload and verify
    project.reload
    assert_equal "Updated Title 1", project.title
    assert_not_equal original_title, project.title
  end

  private

  def sign_in_as(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
