require "test_helper"

class ProductionReadinessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user_one)
    # Clear existing projects for clean test
    @user.projects.destroy_all
    sign_in_as(@user)
  end

  test "complete project management workflow is production ready" do
    # Test 1: Create a project with comprehensive data
    post projects_path, params: {
      project: {
        title: "Production Ready App",
        description: "A fully featured application demonstrating production readiness with comprehensive testing, error handling, and user experience enhancements.",
        technologies_display: "Ruby on Rails, PostgreSQL, Redis, Tailwind CSS, Stimulus",
        live_url: "example.com/demo", # Should be normalized
        source_code_url: "github.com/user/production-app", # Should be normalized
        featured: true,
        status: "published"
      }
    }

    assert_response :redirect
    project = Project.last

    # Verify URL normalization
    assert_equal "https://example.com/demo", project.live_url
    assert_equal "https://github.com/user/production-app", project.source_code_url

    # Verify technologies parsing
    assert_equal ["Ruby on Rails", "PostgreSQL", "Redis", "Tailwind CSS", "Stimulus"], project.technologies_used

    # Verify automatic display_order assignment
    assert_equal 1, project.display_order

    # Test 2: Create multiple projects to test ordering
    second_project = @user.projects.create!(
      title: "Second Project",
      description: "Another project",
      technologies_used: ["Vue.js", "Node.js"],
      status: "draft"
    )

    third_project = @user.projects.create!(
      title: "Third Project",
      description: "Yet another project",
      technologies_used: ["React", "TypeScript"],
      status: "archived"
    )

    # Verify display orders are automatically assigned
    assert_equal 1, project.display_order
    assert_equal 2, second_project.display_order
    assert_equal 3, third_project.display_order

    # Test 3: Test reordering functionality
    new_order = [third_project.id, project.id, second_project.id]

    patch reorder_projects_path,
          params: { project_ids: new_order }.to_json,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]

    # Verify new order
    project.reload
    second_project.reload
    third_project.reload

    assert_equal 2, project.display_order
    assert_equal 3, second_project.display_order
    assert_equal 1, third_project.display_order

    # Test 4: Verify scopes work correctly
    published_projects = Project.published.for_user(@user)
    assert_equal 1, published_projects.count
    assert_includes published_projects, project

    featured_projects = Project.featured.for_user(@user)
    assert_equal 1, featured_projects.count
    assert_includes featured_projects, project

    ordered_projects = Project.for_user(@user).by_display_order
    assert_equal [third_project, project, second_project], ordered_projects.to_a

    # Test 5: Test update functionality
    patch project_path(project), params: {
      project: {
        title: "Updated Production App",
        technologies_display: "Ruby on Rails, PostgreSQL, Redis, Tailwind CSS, Stimulus, Sidekiq",
        featured: false
      }
    }

    assert_response :redirect
    project.reload
    assert_equal "Updated Production App", project.title
    assert_equal 6, project.technologies_used.length
    assert_equal false, project.featured?

    # Test 6: Test validation edge cases
    post projects_path, params: {
      project: {
        title: "", # Invalid
        description: "Test description",
        technologies_display: "Rails"
      }
    }

    assert_response :unprocessable_content
    assert_select ".text-red-700", text: /can't be blank/

    # Test 7: Test technology limit validation
    too_many_techs = (1..15).map { |i| "Technology#{i}" }.join(", ")

    post projects_path, params: {
      project: {
        title: "Too Many Technologies",
        description: "Testing limits",
        technologies_display: too_many_techs
      }
    }

    assert_response :unprocessable_content
    assert_select ".text-red-700", text: /too many technologies/

    # Test 8: Test invalid URL handling
    post projects_path, params: {
      project: {
        title: "Invalid URL Test",
        description: "Testing URL validation",
        technologies_display: "Rails",
        live_url: "not-a-valid-url",
        source_code_url: "javascript:alert('xss')"
      }
    }

    assert_response :unprocessable_content
    assert_select ".text-red-700", text: /must be a valid URL/

    # Test 9: Test deletion
    delete project_path(third_project)
    assert_response :redirect
    assert_not Project.exists?(third_project.id)

    # Test 10: Verify security - user cannot access other user's projects
    other_user = users(:test_user_two)
    other_project = other_user.projects.create!(
      title: "Other User Project",
      description: "Should not be accessible",
      technologies_used: ["Rails"]
    )

    get project_path(other_project)
    assert_response :redirect
    assert_equal "You can only access your own projects.", flash[:alert]

    # Test 11: Test unauthorized reordering
    patch reorder_projects_path,
          params: { project_ids: [other_project.id] }.to_json,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }

    assert_response :unprocessable_content

    # Test 12: Verify projects index shows correct data
    get projects_path
    assert_response :success
    assert_select "h1", text: "My Projects"
    assert_select ".project-card", count: 2 # project and second_project

    # Test 13: Verify project show page displays correctly
    get project_path(project)
    assert_response :success
    assert_select "h1", text: project.title
    assert_includes response.body, project.description
    assert_includes response.body, "Ruby on Rails" # First technology

    puts "✅ All production readiness tests passed!"
    puts "   - CRUD operations: ✅"
    puts "   - Validations: ✅"
    puts "   - URL normalization: ✅"
    puts "   - Technology parsing: ✅"
    puts "   - Display ordering: ✅"
    puts "   - Reordering: ✅"
    puts "   - Scopes: ✅"
    puts "   - Security: ✅"
    puts "   - Error handling: ✅"
    puts "   - Edge cases: ✅"
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
