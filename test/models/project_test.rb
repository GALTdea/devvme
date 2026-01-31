# == Schema Information
#
# Table name: projects
# Database name: primary
#
#  id                :bigint           not null, primary key
#  demo_url          :string
#  description       :text
#  display_order     :integer
#  featured          :boolean
#  github_url        :string
#  live_url          :string
#  source_code_url   :string
#  status            :integer
#  technologies      :text
#  technologies_used :json
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_projects_on_display_order              (display_order)
#  index_projects_on_status                     (status)
#  index_projects_on_user_id                    (user_id)
#  index_projects_on_user_id_and_display_order  (user_id,display_order)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
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
    # Test dangerous protocols
    dangerous_urls = ["javascript:alert('xss')", "data:text/html,<script>alert('xss')</script>", "vbscript:msgbox('xss')", "file:///etc/passwd"]

    dangerous_urls.each do |dangerous_url|
      @project.live_url = dangerous_url
      assert_not @project.valid?, "#{dangerous_url} should be invalid for live_url"
      assert_includes @project.errors[:live_url].join, "cannot use"
    end

    # Test invalid formats
    invalid_urls = ["not-a-url", "just-text", "spaces in url", "http://"]

    invalid_urls.each do |invalid_url|
      @project.live_url = invalid_url
      @project.errors.clear
      @project.valid?
      # The validation message varies based on the specific error
      assert @project.errors[:live_url].any?, "#{invalid_url} should be invalid for live_url"
    end

    # Test FTP (should be rejected as dangerous protocol)
    @project.live_url = "ftp://example.com"
    assert_not @project.valid?
    assert_includes @project.errors[:live_url].join, "cannot use ftp protocol"
  end

  test "should validate source_code_url format" do
    # Test dangerous protocols
    dangerous_urls = ["javascript:alert('xss')", "data:text/html,<script>alert('xss')</script>"]

    dangerous_urls.each do |dangerous_url|
      @project.source_code_url = dangerous_url
      assert_not @project.valid?, "#{dangerous_url} should be invalid for source_code_url"
      assert_includes @project.errors[:source_code_url].join, "cannot use"
    end

    # Test invalid formats
    invalid_urls = ["not-a-url", "just-text"]

    invalid_urls.each do |invalid_url|
      @project.source_code_url = invalid_url
      @project.errors.clear
      @project.valid?
      # The validation message varies based on the specific error
      assert @project.errors[:source_code_url].any?, "#{invalid_url} should be invalid for source_code_url"
    end
  end

  test "should allow valid URLs including user-friendly formats" do
    # Test fully qualified URLs
    valid_urls = ["https://example.com", "http://example.com", "https://subdomain.example.com/path", "https://github.com/user/repo"]

    valid_urls.each do |valid_url|
      @project.live_url = valid_url
      @project.source_code_url = valid_url
      assert @project.valid?, "#{valid_url} should be valid"
    end

    # Test user-friendly formats (domain only)
    user_friendly_urls = ["devv.me", "example.com", "github.com/user/repo", "subdomain.example.com"]

    user_friendly_urls.each do |friendly_url|
      @project.live_url = friendly_url
      @project.source_code_url = friendly_url
      assert @project.valid?, "#{friendly_url} should be valid"
    end
  end

  test "should reject URLs without proper domains" do
    # Test domains that should be allowed
    valid_domains = ["localhost", "192.168.1.1", "example.com"]

    valid_domains.each do |valid_domain|
      @project.live_url = valid_domain
      @project.errors.clear
      assert @project.valid?, "#{valid_domain} should be allowed"
    end

    # Test truly invalid domains
    invalid_domains = ["just-text", "no-dots-no-ip"]

    invalid_domains.each do |invalid_domain|
      @project.live_url = invalid_domain
      @project.errors.clear
      @project.valid?
      assert_includes @project.errors[:live_url].join, "must include a valid domain", "#{invalid_domain} should require a valid domain"
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

  test "reorder_for_user should update display_order correctly" do
    user = users(:test_user_one)
    project1 = Project.create!(
      title: "First Project",
      description: "First project description",
      technologies_used: ["Ruby", "Rails"],
      user: user,
      display_order: 1
    )
    project2 = Project.create!(
      title: "Second Project",
      description: "Second project description",
      technologies_used: ["JavaScript", "React"],
      user: user,
      display_order: 2
    )
    project3 = Project.create!(
      title: "Third Project",
      description: "Third project description",
      technologies_used: ["Python", "Django"],
      user: user,
      display_order: 3
    )

    # Reorder: project3, project1, project2
    new_order = [project3.id, project1.id, project2.id]
    result = Project.reorder_for_user(user, new_order)

    assert result, "Reorder should succeed"

    # Reload and check new order
    project1.reload
    project2.reload
    project3.reload

    assert_equal 2, project1.display_order
    assert_equal 3, project2.display_order
    assert_equal 1, project3.display_order
  end

  test "reorder_for_user should reject invalid project ids" do
    user = users(:test_user_one)
    result = Project.reorder_for_user(user, [999, 1000])
    assert_not result, "Reorder should fail with invalid IDs"
  end

  test "reorder_for_user should reject projects not owned by user" do
    user1 = users(:test_user_one)
    user2 = users(:test_user_two)

    project = Project.create!(
      title: "User 2 Project",
      description: "Project belonging to user 2",
      technologies_used: ["Ruby"],
      user: user2,
      display_order: 1
    )

    result = Project.reorder_for_user(user1, [project.id])
    assert_not result, "Reorder should fail for projects not owned by user"
  end
end
