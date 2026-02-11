# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                        :bigint           not null, primary key
#  account_status            :integer          default("pending_activation"), not null
#  admin_notes               :text
#  allow_career_architect    :boolean          default(FALSE), not null
#  bio                       :text
#  contact_email             :string
#  email                     :string           default(""), not null
#  encrypted_password        :string           default(""), not null
#  featured                  :boolean          default(FALSE)
#  featured_at               :datetime
#  full_name                 :string(100)
#  github_oauth_connected_at :datetime
#  github_oauth_scope        :string
#  github_oauth_token        :text
#  github_url                :string
#  headline                  :text
#  invitation_accepted_at    :datetime
#  invitation_access_code    :string
#  invitation_sent_at        :datetime
#  invitation_token          :string
#  job_title                 :string
#  last_login_at             :datetime
#  linkedin_url              :string
#  location                  :string
#  open_for_work             :boolean          default(FALSE), not null
#  phone                     :string
#  provider                  :string
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string
#  resume_url                :string
#  role                      :integer          default("user"), not null
#  skills                    :json
#  slug                      :string           not null
#  social_image_version      :integer          default(1), not null
#  suspended_at              :datetime
#  suspension_reason         :text
#  twitter_url               :string
#  uid                       :string
#  username                  :string           not null
#  website_url               :string
#  work_preferences          :jsonb            not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_users_on_account_status             (account_status)
#  index_users_on_allow_career_architect     (allow_career_architect) WHERE (allow_career_architect = true)
#  index_users_on_email                      (email) UNIQUE
#  index_users_on_featured                   (featured)
#  index_users_on_github_oauth_connected_at  (github_oauth_connected_at)
#  index_users_on_invitation_accepted_at     (invitation_accepted_at)
#  index_users_on_invitation_access_code     (invitation_access_code)
#  index_users_on_invitation_sent_at         (invitation_sent_at)
#  index_users_on_invitation_token           (invitation_token) UNIQUE
#  index_users_on_last_login_at              (last_login_at)
#  index_users_on_provider_and_uid           (provider,uid) UNIQUE
#  index_users_on_reset_password_token       (reset_password_token) UNIQUE
#  index_users_on_role                       (role)
#  index_users_on_slug                       (slug) UNIQUE
#  index_users_on_suspended_at               (suspended_at)
#  index_users_on_username                   (username) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test@example.com",
      password: "password123",
      username: "testuser",
      full_name: "Test User"
    )
  end

  # Basic validation tests
  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require password" do
    @user.password = nil
    assert_not @user.valid?
    assert_includes @user.errors[:password], "can't be blank"
  end

  test "should require username" do
    @user.username = nil
    assert_not @user.valid?
    assert_includes @user.errors[:username], "can't be blank"
  end

  # Username validation tests
  test "should require unique username" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:username], "has already been taken"
  end

  test "should enforce username length between 3 and 30 characters" do
    @user.username = "ab"
    assert_not @user.valid?
    assert_includes @user.errors[:username], "is too short (minimum is 3 characters)"

    @user.username = "a" * 31
    assert_not @user.valid?
    assert_includes @user.errors[:username], "is too long (maximum is 30 characters)"
  end

  test "should only allow valid username format" do
    invalid_usernames = [ "user name", "user@name", "user.name", "user!name" ]
    invalid_usernames.each do |invalid_username|
      @user.username = invalid_username
      assert_not @user.valid?, "#{invalid_username} should be invalid"
      assert_includes @user.errors[:username], "can only contain letters, numbers, hyphens, and underscores"
    end

    valid_usernames = [ "username", "user_name", "user-name", "user123", "123user" ]
    valid_usernames.each do |valid_username|
      @user.username = valid_username
      @user.valid? # Clear previous errors
      assert_not_includes @user.errors[:username], "can only contain letters, numbers, hyphens, and underscores"
    end
  end

  test "should be case insensitive for username uniqueness" do
    @user.username = "TestUser"
    @user.save

    duplicate_user = @user.dup
    duplicate_user.username = "testuser"
    duplicate_user.email = "different@example.com"

    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:username], "has already been taken"
  end

  # Full name validation tests
  test "should enforce full_name maximum length" do
    @user.full_name = "a" * 101
    assert_not @user.valid?
    assert_includes @user.errors[:full_name], "is too long (maximum is 100 characters)"
  end

  test "should allow blank full_name" do
    @user.full_name = ""
    assert @user.valid?
  end

  # Bio validation tests
  test "should enforce bio maximum length" do
    @user.bio = "a" * 501
    assert_not @user.valid?
    assert_includes @user.errors[:bio], "is too long (maximum is 500 characters)"
  end

  test "should allow blank bio" do
    @user.bio = ""
    assert @user.valid?
  end

  # URL validation tests
  test "should validate URL format for social links" do
    invalid_urls = [ "not-a-url", "ftp://example.com", "javascript:alert('xss')" ]

    invalid_urls.each do |invalid_url|
      @user.github_url = invalid_url
      assert_not @user.valid?, "#{invalid_url} should be invalid for github_url"
      assert_includes @user.errors[:github_url], "must be a valid URL"

      @user.linkedin_url = invalid_url
      @user.valid? # Trigger validation
      assert_includes @user.errors[:linkedin_url], "must be a valid URL"

      @user.website_url = invalid_url
      @user.valid? # Trigger validation
      assert_includes @user.errors[:website_url], "must be a valid URL"
    end
  end

  test "should allow valid URLs for social links" do
    valid_urls = [ "https://example.com", "http://example.com", "https://subdomain.example.com/path" ]

    valid_urls.each do |valid_url|
      @user.github_url = valid_url
      @user.linkedin_url = valid_url
      @user.website_url = valid_url
      assert @user.valid?, "#{valid_url} should be valid"
    end
  end

  test "should allow blank URLs for social links" do
    @user.github_url = ""
    @user.linkedin_url = ""
    @user.website_url = ""
    assert @user.valid?
  end

  # URL normalization tests
  test "should normalize URLs on save" do
    @user.github_url = "github.com/user"
    @user.linkedin_url = "linkedin.com/in/user"
    @user.website_url = "example.com"
    @user.save

    assert_equal "https://github.com/user", @user.github_url
    assert_equal "https://linkedin.com/in/user", @user.linkedin_url
    assert_equal "https://example.com", @user.website_url
  end

  test "should not modify URLs that already have protocol" do
    @user.github_url = "https://github.com/user"
    @user.linkedin_url = "http://linkedin.com/in/user"
    @user.save

    assert_equal "https://github.com/user", @user.github_url
    assert_equal "http://linkedin.com/in/user", @user.linkedin_url
  end

  # FriendlyId tests
  test "should generate slug from username" do
    @user.save
    assert_equal @user.username, @user.slug
  end

  test "should regenerate slug when username changes" do
    @user.save
    old_slug = @user.slug

    @user.update(username: "newusername")
    assert_not_equal old_slug, @user.slug
    assert_equal "newusername", @user.slug
  end

  # Association tests
  test "should have many projects" do
    assert_respond_to @user, :projects
  end

  test "should destroy associated projects when user is destroyed" do
    @user.save
    @user.projects.create!(
      title: "Test Project",
      description: "Test Description",
      technologies_used: ["Rails", "Ruby"],
      status: "published"
    )

    assert_difference "Project.count", -1 do
      @user.destroy
    end
  end

  # Avatar validation tests
  test "should validate avatar content type" do
    # This would require a more complex setup with actual file uploads
    # For now, we'll test the validation method directly
    @user.save

    # Create a mock attachment with invalid content type
    @user.avatar.attach(
      io: StringIO.new("fake image data"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    assert_not @user.valid?
    assert_includes @user.errors[:avatar], "must be a JPEG or PNG image"
  end

  # Statistics methods tests
  test "projects_count should return number of projects" do
    @user.save
    assert_equal 0, @user.projects_count

    @user.projects.create!(
      title: "Project 1",
      description: "Description 1",
      technologies_used: ["Rails"],
      status: "published"
    )

    assert_equal 1, @user.projects_count
  end

  test "published_projects_count should return number of published projects" do
    @user.save

    @user.projects.create!(
      title: "Draft Project",
      description: "Description",
      technologies_used: ["Rails"],
      status: "draft"
    )

    @user.projects.create!(
      title: "Published Project",
      description: "Description",
      technologies_used: ["Rails"],
      status: "published"
    )

    assert_equal 1, @user.published_projects_count
  end

  test "profile_completion_percentage should calculate correctly" do
    @user.save

    # Username and full_name filled (2/13 = ~15%)
    completion = @user.profile_completion_percentage
    assert_equal 15, completion

    # Add more fields
    @user.update(
      full_name: "Test User",
      bio: "Test bio",
      job_title: "Developer",
      location: "Test City"
    )

    completion = @user.profile_completion_percentage
    assert_equal 38, completion # 5/13 = ~38%
  end

  test "display_name should return full_name if present, otherwise username" do
    @user.full_name = ""
    assert_equal @user.username, @user.display_name

    @user.full_name = "Test User"
    assert_equal "Test User", @user.display_name
  end

  test "recent_projects should return published projects in desc order" do
    @user.save

    old_project = @user.projects.create!(
      title: "Old Project",
      description: "Description",
      technologies_used: ["Rails"],
      status: "published",
      created_at: 2.days.ago
    )

    new_project = @user.projects.create!(
      title: "New Project",
      description: "Description",
      technologies_used: ["Rails"],
      status: "published",
      created_at: 1.day.ago
    )

    draft_project = @user.projects.create!(
      title: "Draft Project",
      description: "Description",
      technologies_used: ["Rails"],
      status: "draft"
    )

    recent = @user.recent_projects
    assert_equal 2, recent.count
    assert_equal new_project, recent.first
    assert_equal old_project, recent.second
    assert_not_includes recent, draft_project
  end

  test "from_omniauth creates new user with github provider and profile fields" do
    auth = {
      "provider" => "github",
      "uid" => "12345",
      "info" => {
        "email" => "oauth_new@example.com",
        "nickname" => "octocat",
        "name" => "Octo Cat",
        "description" => "Ruby developer",
        "blog" => "octo.dev",
        "urls" => { "GitHub" => "https://github.com/octocat" }
      },
      "credentials" => { "token" => "token123", "scope" => "read:user,user:email,repo" }
    }

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth)
      assert user.persisted?
      assert_equal "github", user.provider
      assert_equal "12345", user.uid
      assert_equal "oauth_new@example.com", user.email
      assert_equal "octocat", user.username
      assert_equal "Octo Cat", user.full_name
      assert_equal "Ruby developer", user.bio
      assert_equal "https://octo.dev", user.website_url
      assert_equal "https://github.com/octocat", user.github_url
      assert user.github_oauth_connected?
      assert_equal "token123", user.github_oauth_token_for_insights
      assert_equal "read:user,user:email,repo", user.github_oauth_scope
      assert user.github_oauth_connected_at.present?
    end
  end

  test "from_omniauth links existing user by email" do
    existing = User.create!(
      email: "oauth_existing@example.com",
      password: "password123",
      username: "existinguser",
      full_name: ""
    )

    auth = {
      "provider" => "github",
      "uid" => "99999",
      "info" => {
        "email" => "oauth_existing@example.com",
        "nickname" => "othername",
        "name" => "Existing User",
        "urls" => { "GitHub" => "https://github.com/othername" }
      }
    }

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth)
      assert_equal existing.id, user.id
      assert_equal "github", user.provider
      assert_equal "99999", user.uid
      assert_equal "Existing User", user.full_name
      assert_equal "https://github.com/othername", user.github_url
    end
  end
end
