require "application_system_test_case"

class ProjectsTest < ApplicationSystemTestCase
  setup do
    @user = users(:test_user_one)
    @other_user = users(:test_user_two)
    @project1 = projects(:test_project_one)
    @project2 = projects(:test_project_two)

    # Make project1 belong to current user and ensure user can access projects
    @project1.update!(user: @user)
    @user.update!(account_status: :active)
  end

    test "user can view projects index" do
    sign_in_as(@user)
    
    # Wait for redirect to dashboard after sign-in and verify we're signed in
    assert_text "Welcome back", wait: 5

    visit projects_path

    assert_selector "h1", text: "My Projects"
    assert_text @project1.title
    assert_no_text @project2.title # Should not see other user's projects
  end

  test "user can create a new project" do
    sign_in_as(@user)
    
    # After sign-in, Devise redirects to dashboard_path
    # Wait for redirect and verify we're signed in by checking dashboard content
    assert_text "Welcome back", wait: 5
    
    # Now navigate to projects page - user should be authenticated
    visit projects_path

    # Verify we're on the projects page (not redirected to explore)
    # If redirected to explore, we'd see "Explore Projects" instead
    assert_selector "h1", text: "My Projects", wait: 5
    assert_no_selector "h1", text: "Explore Projects"

    # The link contains SVG + text "New Project", so find by text content
    # Capybara's click_link will find links containing the text, even with SVG children
    click_link "New Project", wait: 5

    fill_in "Title", with: "My Awesome Project"
    fill_in "Description", with: "This is an awesome project description"
    fill_in "Technologies", with: "Rails, Ruby, PostgreSQL"
    fill_in "Live URL", with: "https://myproject.com"
    fill_in "Source Code URL", with: "https://github.com/user/myproject"
    check "Featured"
    select "Published", from: "Status"

    click_on "Create Project"

    assert_text "Project was successfully created"
    assert_text "My Awesome Project"
    assert_text "This is an awesome project description"
    assert_text "Rails, Ruby, PostgreSQL"
  end

  test "user sees validation errors when creating invalid project" do
    sign_in_as(@user)

    visit new_project_path
    # new project path is /projects/new

    # Submit empty form
    click_on "Create Project"

    assert_text "can't be blank"
    assert_current_path projects_path
  end

  test "user can edit their project" do
    sign_in_as(@user)

    visit project_path(@project1)
    click_on "Edit"

    fill_in "Title", with: "Updated Project Title"
    fill_in "Description", with: "Updated project description"

    click_on "Update Project"

    assert_text "Project was successfully updated"
    assert_text "Updated Project Title"
    assert_text "Updated project description"
  end

  test "user can delete their project" do
    sign_in_as(@user)

    visit project_path(@project1)

    accept_confirm do
      click_on "Delete"
    end

    assert_text "Project was successfully deleted"
    assert_current_path projects_path
    assert_no_text @project1.title
  end

  test "user can reorder projects via drag and drop" do
    sign_in_as(@user)

    # Create a second project for the user
    project2 = @user.projects.create!(
      title: "Second Project",
      description: "Second project description",
      technologies_used: ["Vue", "Node.js"],
      display_order: 2
    )

    visit projects_path

    # Verify initial order
    projects = page.all("[data-sortable-item]")
    assert_equal @project1.title, projects.first.find("h3").text
    assert_equal project2.title, projects.last.find("h3").text

    # Note: Actual drag and drop testing would require a more sophisticated setup
    # For now, we'll test the reorder endpoint functionality through the controller tests
  end

  test "user can upload project thumbnail" do
    sign_in_as(@user)

    visit edit_project_path(@project1)

    attach_file "Thumbnail", Rails.root.join("test/fixtures/files/test_image.png")
    click_on "Update Project"

    assert_text "Project was successfully updated"
    # Verify thumbnail is displayed (would need to check for img tag)
  end

  test "user can upload project images" do
    sign_in_as(@user)

    visit edit_project_path(@project1)

    attach_file "Images", Rails.root.join("test/fixtures/files/test_image.png")
    click_on "Update Project"

    assert_text "Project was successfully updated"
    # Verify images are displayed
  end

  test "user can view project details" do
    sign_in_as(@user)

    visit project_path(@project1)

    assert_text @project1.title
    assert_text @project1.description
    assert_text @project1.technologies_used.join(", ")

    if @project1.live_url.present?
      assert_link "View Live Site", href: @project1.live_url
    end

    if @project1.source_code_url.present?
      assert_link "View Source Code", href: @project1.source_code_url
    end
  end

  test "user cannot view other user's draft project" do
    sign_in_as(@user)
    @project2.update!(status: :draft)

    visit project_path(@project2)

    # Redirects to explore then to explore index with not found
    assert_text "Project not found"
    assert_current_path public_projects_path
  end

  test "guest user is redirected to login" do
    visit projects_path

    assert_current_path new_user_session_path
  end

  test "user can filter projects by status" do
    skip "Feature not yet implemented - would test status filtering"
  end

  test "user can search projects" do
    skip "Feature not yet implemented - would test search functionality"
  end

  test "projects display correctly on mobile" do
    # Test responsive design
    resize_window_to(:mobile)
    sign_in_as(@user)

    visit projects_path

    assert_text @project1.title
    # Verify mobile layout (would need specific mobile assertions)
  end

  test "loading states are shown during AJAX operations" do
    sign_in_as(@user)

    visit projects_path

    # This would test loading spinners and states during reordering
    # Would require JavaScript driver and specific assertions
    skip "Requires JavaScript driver for proper testing"
  end

  private

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_on "Log in"
    
    # Wait for Devise redirect to complete (redirects to dashboard after sign-in)
    # Capybara will wait for navigation, but we need to ensure the session is established
    # The redirect happens automatically via after_sign_in_path_for
  end

  def resize_window_to(size)
    case size
    when :mobile
      page.driver.browser.manage.window.resize_to(375, 667)
    when :tablet
      page.driver.browser.manage.window.resize_to(768, 1024)
    when :desktop
      page.driver.browser.manage.window.resize_to(1200, 800)
    end
  end
end
