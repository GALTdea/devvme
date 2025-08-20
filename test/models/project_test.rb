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
      technologies: "Rails, Ruby, PostgreSQL",
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
    @project.technologies = nil
    assert_not @project.valid?
    assert_includes @project.errors[:technologies], "can't be blank"
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
    @project.technologies = "a" * 501
    assert_not @project.valid?
    assert_includes @project.errors[:technologies], "is too long (maximum is 500 characters)"
  end

  # URL validation tests
  test "should validate github_url format" do
    invalid_urls = [ "not-a-url", "ftp://example.com", "javascript:alert('xss')" ]

    invalid_urls.each do |invalid_url|
      @project.github_url = invalid_url
      assert_not @project.valid?, "#{invalid_url} should be invalid for github_url"
      assert_includes @project.errors[:github_url], "must be a valid URL"
    end
  end

  test "should validate demo_url format" do
    invalid_urls = [ "not-a-url", "ftp://example.com", "javascript:alert('xss')" ]

    invalid_urls.each do |invalid_url|
      @project.demo_url = invalid_url
      assert_not @project.valid?, "#{invalid_url} should be invalid for demo_url"
      assert_includes @project.errors[:demo_url], "must be a valid URL"
    end
  end

  test "should allow valid URLs" do
    valid_urls = [ "https://example.com", "http://example.com", "https://subdomain.example.com/path" ]

    valid_urls.each do |valid_url|
      @project.github_url = valid_url
      @project.demo_url = valid_url
      assert @project.valid?, "#{valid_url} should be valid"
    end
  end

  test "should allow blank URLs" do
    @project.github_url = ""
    @project.demo_url = ""
    assert @project.valid?
  end

  # URL normalization tests
  test "should normalize URLs on save" do
    @project.github_url = "github.com/user/repo"
    @project.demo_url = "example.com"
    @project.save

    assert_equal "https://github.com/user/repo", @project.github_url
    assert_equal "https://example.com", @project.demo_url
  end

  test "should not modify URLs that already have protocol" do
    @project.github_url = "https://github.com/user/repo"
    @project.demo_url = "http://example.com"
    @project.save

    assert_equal "https://github.com/user/repo", @project.github_url
    assert_equal "http://example.com", @project.demo_url
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
      technologies: "Rails"
    )
    # Update the created_at after creation
    older_project.update_column(:created_at, 2.days.ago)

    newer_project = @user.projects.create!(
      title: "Newer Project",
      description: "Description",
      technologies: "Rails"
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
      technologies: "Rails",
      featured: true
    )

    regular_project = @user.projects.create!(
      title: "Regular Project",
      description: "Description",
      technologies: "Rails",
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
      technologies: "Rails",
      status: "draft"
    )

    archived_project = @user.projects.create!(
      title: "Archived Project",
      description: "Description",
      technologies: "Rails",
      status: "archived"
    )

    published_projects = Project.published
    assert_includes published_projects, @project
    assert_not_includes published_projects, draft_project
    assert_not_includes published_projects, archived_project
  end

  # Featured attribute tests
  test "should default featured to false" do
    new_project = Project.new
    assert_equal false, new_project.featured
  end

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
      technologies: "Rails",
      status: "draft",
      featured: true
    )

    published_regular = @user.projects.create!(
      title: "Published Regular",
      description: "Description",
      technologies: "Rails",
      status: "published",
      featured: false
    )

    published_featured = Project.published.featured
    assert_includes published_featured, @project
    assert_not_includes published_featured, draft_featured
    assert_not_includes published_featured, published_regular
  end
end
