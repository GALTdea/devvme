require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      username: "testuser"
    )

    @project = @user.projects.build(
      title: "Test Project",
      description: "A test project description",
      technologies_used: ["Rails", "Ruby", "PostgreSQL"],
      status: "published"
    )
  end

  # Basic validation tests
  test "should be valid with valid attributes" do
    assert @project.valid?
  end

  test "should require title" do
    @project.title = nil
    assert_not @project.valid?
    assert_includes @project.errors[:title], "can't be blank"
  end

  test "should require description" do
    @project.description = nil
    assert_not @project.valid?
    assert_includes @project.errors[:description], "can't be blank"
  end

  test "should require technologies" do
    @project.technologies_used = []
    assert_not @project.valid?
    assert_includes @project.errors[:technologies_used], "must include at least one technology"
  end

  test "should require user" do
    @project.user = nil
    assert_not @project.valid?
    assert_includes @project.errors[:user], "must exist"
  end

  # Length validation tests
  test "should enforce title maximum length" do
    @project.title = "a" * 101
    assert_not @project.valid?
    assert_includes @project.errors[:title], "is too long (maximum is 100 characters)"
  end

  test "should enforce description maximum length" do
    @project.description = "a" * 1001
    assert_not @project.valid?
    assert_includes @project.errors[:description], "is too long (maximum is 1000 characters)"
  end

  test "should enforce technologies maximum length" do
    long_tech = "a" * 51
    @project.technologies_used = [long_tech]  # Each tech limited to 50 chars
    assert_not @project.valid?
    assert_includes @project.errors[:technologies_used], "technology '#{long_tech}' is too long (maximum 50 characters)"
  end

  test "should enforce maximum number of technologies" do
    @project.technologies_used = (1..11).map { |i| "Tech#{i}" }  # 11 technologies, max is 10
    assert_not @project.valid?
    assert_includes @project.errors[:technologies_used], "too many technologies (maximum 10)"
  end

  # URL validation tests
  test "should validate live_url format" do
    invalid_urls = [ "not-a-url", "ftp://example.com", "javascript:alert('xss')" ]

    invalid_urls.each do |invalid_url|
      @project.live_url = invalid_url
      assert_not @project.valid?, "#{invalid_url} should be invalid for live_url"
      assert_includes @project.errors[:live_url], "must be a valid URL"
    end
  end

  test "should validate source_code_url format" do
    invalid_urls = [ "not-a-url", "ftp://example.com", "javascript:alert('xss')" ]

    invalid_urls.each do |invalid_url|
      @project.source_code_url = invalid_url
      assert_not @project.valid?, "#{invalid_url} should be invalid for source_code_url"
      assert_includes @project.errors[:source_code_url], "must be a valid URL"
    end
  end

  test "should allow valid URLs" do
    valid_urls = [ "https://example.com", "http://example.com", "https://subdomain.example.com/path" ]

    valid_urls.each do |valid_url|
      @project.live_url = valid_url
      @project.source_code_url = valid_url
      assert @project.valid?, "#{valid_url} should be valid"
    end
  end

  test "should allow blank URLs" do
    @project.live_url = ""
    @project.source_code_url = ""
    assert @project.valid?
  end

  # URL normalization tests
  test "should normalize URLs on save" do
    @project.live_url = "github.com/user/repo"
    @project.source_code_url = "example.com"
    @project.save

    assert_equal "https://github.com/user/repo", @project.live_url
    assert_equal "https://example.com", @project.source_code_url
  end

  test "should not modify URLs that already have protocol" do
    @project.live_url = "https://github.com/user/repo"
    @project.source_code_url = "http://example.com"
    @project.save

    assert_equal "https://github.com/user/repo", @project.live_url
    assert_equal "http://example.com", @project.source_code_url
  end

  # Status enum tests
  test "should have draft status by default" do
    new_project = Project.new
    assert_equal "draft", new_project.status
  end

  test "should allow valid status values" do
    valid_statuses = [ "draft", "published", "archived" ]

    valid_statuses.each do |status|
      @project.status = status
      assert @project.valid?, "#{status} should be a valid status"
    end
  end

  test "should provide status query methods" do
    @project.status = "draft"
    assert @project.draft?
    assert_not @project.published?
    assert_not @project.archived?

    @project.status = "published"
    assert_not @project.draft?
    assert @project.published?
    assert_not @project.archived?

    @project.status = "archived"
    assert_not @project.draft?
    assert_not @project.published?
    assert @project.archived?
  end

  # Association tests
  test "should belong to user" do
    assert_respond_to @project, :user
    assert_equal @user, @project.user
  end

  test "should have many attached images" do
    assert_respond_to @project, :images
  end

  test "should have one attached thumbnail" do
    assert_respond_to @project, :thumbnail
  end

  # Scope tests
  test "recent scope should order by created_at desc" do
    # Clear all projects first to ensure clean test
    Project.delete_all

    @project.save

    older_project = @user.projects.create!(
      title: "Older Project",
      description: "Description",
      technologies_used: ["Rails"]
    )
    # Update the created_at after creation
    older_project.update_column(:created_at, 2.days.ago)

    newer_project = @user.projects.create!(
      title: "Newer Project",
      description: "Description",
      technologies_used: ["Rails"]
    )
    # Update the created_at after creation
    newer_project.update_column(:created_at, 1.day.ago)

    recent_projects = Project.recent
    assert_equal @project, recent_projects.first
    assert_equal newer_project, recent_projects.second
    assert_equal older_project, recent_projects.third
  end

  test "featured scope should return only featured projects" do
    @project.save

    featured_project = @user.projects.create!(
      title: "Featured Project",
      description: "Description",
      technologies_used: ["Rails"],
      featured: true
    )

    regular_project = @user.projects.create!(
      title: "Regular Project",
      description: "Description",
      technologies_used: ["Rails"],
      featured: false
    )

    featured_projects = Project.featured
    assert_includes featured_projects, featured_project
    assert_not_includes featured_projects, regular_project
    assert_not_includes featured_projects, @project
  end

  test "published scope should return only published projects" do
    @project.save # published by default in setup

    draft_project = @user.projects.create!(
      title: "Draft Project",
      description: "Description",
      technologies_used: ["Rails"],
      status: "draft"
    )

    archived_project = @user.projects.create!(
      title: "Archived Project",
      description: "Description",
      technologies_used: ["Rails"],
      status: "archived"
    )

    published_projects = Project.published
    assert_includes published_projects, @project
    assert_not_includes published_projects, draft_project
    assert_not_includes published_projects, archived_project
  end

  test "by_display_order scope should order by display_order" do
    # Clear projects and create in specific order
    Project.delete_all

    project1 = @user.projects.create!(
      title: "Third", description: "Desc", technologies_used: ["Rails"], display_order: 3
    )
    project2 = @user.projects.create!(
      title: "First", description: "Desc", technologies_used: ["Rails"], display_order: 1
    )
    project3 = @user.projects.create!(
      title: "Second", description: "Desc", technologies_used: ["Rails"], display_order: 2
    )

    ordered_projects = Project.by_display_order
    assert_equal [project2, project3, project1], ordered_projects.to_a
  end

  test "for_user scope should filter by user" do
    other_user = User.create!(email: "other@example.com", password: "password123", username: "otheruser")
    @project.save!

    other_project = other_user.projects.create!(
      title: "Other Project", description: "Desc", technologies_used: ["Rails"]
    )

    user_projects = Project.for_user(@user)
    assert_includes user_projects, @project
    assert_not_includes user_projects, other_project
  end

  # Display order tests
  test "should auto-set display_order on creation" do
    # Save the first project
    @project.save!
    assert_equal 1, @project.display_order

    # Create second project for same user
    second_project = @user.projects.create!(
      title: "Second Project",
      description: "Another project",
      technologies_used: ["Vue"]
    )
    assert_equal 2, second_project.display_order
  end

  test "should allow manual display_order setting" do
    @project.display_order = 5
    @project.save!
    assert_equal 5, @project.display_order
  end

  test "should validate display_order is positive integer" do
    @project.display_order = 0
    assert_not @project.valid?
    assert_includes @project.errors[:display_order], "must be greater than 0"

    @project.display_order = -1
    assert_not @project.valid?
    assert_includes @project.errors[:display_order], "must be greater than 0"
  end

  # Technologies display tests
  test "should handle technologies_display getter and setter" do
    @project.technologies_used = ["Rails", "Ruby", "PostgreSQL"]
    assert_equal "Rails, Ruby, PostgreSQL", @project.technologies_display

    @project.technologies_display = "Vue, Node.js, MongoDB"
    assert_equal ["Vue", "Node.js", "MongoDB"], @project.technologies_used
  end

  test "should handle empty technologies_display" do
    @project.technologies_display = ""
    assert_equal [], @project.technologies_used
  end

  # Featured attribute tests - updated to match current model
  test "should allow setting featured to true" do
    @project.featured = true
    assert @project.valid?
    assert @project.featured?
  end

  # Combined scope tests
  test "should chain scopes correctly" do
    @project.update!(featured: true)

    draft_featured = @user.projects.create!(
      title: "Draft Featured",
      description: "Description",
      technologies_used: ["Rails"],
      status: "draft",
      featured: true
    )

    published_regular = @user.projects.create!(
      title: "Published Regular",
      description: "Description",
      technologies_used: ["Rails"],
      status: "published",
      featured: false
    )

    published_featured = Project.published.featured
    assert_includes published_featured, @project
    assert_not_includes published_featured, draft_featured
    assert_not_includes published_featured, published_regular
  end
end
