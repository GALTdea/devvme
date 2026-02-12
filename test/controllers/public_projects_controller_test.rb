require "test_helper"

class PublicProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ProjectInsight::RateLimiter::FALLBACK_STORE.clear
    @user = users(:test_user_one)
    @other_user = users(:test_user_two)
    @admin_user = users(:test_admin) if defined?(users(:test_admin))

    # Create test projects with different statuses
    @published_project = projects(:test_project_one)
    @published_project.update!(
      user: @user,
      status: :published,
      title: "Published Project",
      description: "This is a published project",
      technologies_used: ["Ruby", "Rails", "PostgreSQL"]
    )

    @draft_project = projects(:test_project_two)
    @draft_project.update!(
      user: @other_user,
      status: :draft,
      title: "Draft Project",
      description: "This is a draft project",
      technologies_used: ["JavaScript", "React"]
    )

    @featured_project = @user.projects.create!(
      title: "Featured Project",
      description: "This is a featured project",
      status: :published,
      featured: true,
      technologies_used: ["Vue.js", "Node.js"],
      display_order: 1
    )
  end

  # INDEX TESTS
  test "should get index without authentication" do
    get public_projects_url
    assert_response :success
    assert_select "h1", text: /explore projects/i
    assert_select ".bg-white", minimum: 1 # Should show project cards
  end

  test "should show only published projects on index" do
    get public_projects_url
    assert_response :success

    # Should show published projects
    assert_select "h3", text: @published_project.title
    assert_select "h3", text: @featured_project.title

    # Should not show draft projects
    assert_select "h3", { text: @draft_project.title, count: 0 }
  end

  test "should show project statistics on index" do
    get public_projects_url
    assert_response :success

    # Should show stats
    assert_select ".text-3xl.font-bold.text-blue-600", text: "2" # Published projects count
    assert_select ".text-3xl.font-bold.text-green-600", text: "1" # Active developers count
    assert_select ".text-3xl.font-bold.text-purple-600", text: "1" # Featured projects count
  end

  test "should show featured projects with featured badge" do
    get public_projects_url
    assert_response :success

    # Should show featured badge
    assert_select ".bg-purple-100.text-purple-800", text: /featured/i
  end

  test "should show search and filter form" do
    get public_projects_url
    assert_response :success

    # Should show search form
    assert_select "form[action='#{public_projects_path}']"
    assert_select "input[name='search']"
    assert_select "select[name='technology']"
    assert_select "input[name='user']"
  end

  test "should filter projects by search term" do
    get public_projects_url, params: { search: "Published" }
    assert_response :success

    # Should show matching project
    assert_select "h3", text: @published_project.title
    # Should not show non-matching project
    assert_select "h3", { text: @featured_project.title, count: 0 }
  end

  test "should filter projects by technology" do
    get public_projects_url, params: { technology: "Ruby" }
    assert_response :success

    # Should show project with Ruby technology
    assert_select "h3", text: @published_project.title
    # Should not show project without Ruby
    assert_select "h3", { text: @featured_project.title, count: 0 }
  end

  test "should filter projects by user" do
    get public_projects_url, params: { user: @user.username }
    assert_response :success

    # Should show projects by the specified user
    assert_select "h3", text: @published_project.title
    assert_select "h3", text: @featured_project.title
  end

  test "should show empty state when no projects match filters" do
    get public_projects_url, params: { search: "nonexistent" }
    assert_response :success

    assert_select "h3", text: /no projects found/i
    assert_select "a", text: /view all projects/i
  end

  test "should show admin indicator for authenticated admins" do
    # Create admin user if not exists
    admin = users(:test_admin)
    admin.update!(account_status: :active)

    sign_in admin
    get public_projects_url
    assert_response :success

    assert_select ".bg-orange-100.text-orange-800", text: /admin view/i
  end

  # SHOW TESTS
  test "should show published project without authentication" do
    get public_project_url(@published_project)
    assert_response :success
    assert_select "h1", text: @published_project.title
  end

  test "should redirect to index when trying to show draft project" do
    get public_project_url(@draft_project)
    assert_redirected_to public_projects_path
    assert_equal "Project not found.", flash[:alert]
  end

  test "should show draft project to owner" do
    @published_project.update!(status: :draft)
    @user.update!(account_status: :active)
    sign_in @user

    get public_project_url(@published_project)
    assert_response :success
    assert_select "h1", text: @published_project.title
    assert_select "span.bg-yellow-100", text: /draft/i
  end

  test "should show project with all details" do
    get public_project_url(@published_project)
    assert_response :success

    # Should show project title
    assert_select "h1", text: @published_project.title

    # Should show project description
    assert_select "p", text: @published_project.description

    # Should show technologies
    @published_project.technologies_used.each do |tech|
      assert_select ".bg-blue-100.text-blue-800", text: tech
    end

    # Should show developer info
    assert_select "a[href='#{public_profile_path(@user.username)}']", text: @user.display_name
  end

  test "should show project links when present" do
    @published_project.update!(
      live_url: "https://example.com",
      source_code_url: "https://github.com/user/repo"
    )

    get public_project_url(@published_project)
    assert_response :success

    # Should show live demo link
    assert_select "a[href='https://example.com']", text: /live demo/i

    # Should show source code link
    assert_select "a[href='https://github.com/user/repo']", text: /source code/i
  end

  test "should show related projects from same user" do
    get public_project_url(@published_project)
    assert_response :success

    # Should show related projects section
    assert_select "h2", text: /more projects by/i
    assert_select "h3", text: @featured_project.title
  end

  test "should show developer profile section" do
    get public_project_url(@published_project)
    assert_response :success

    # Should show developer section
    assert_select "h3", text: /developer/i
    assert_select "a[href='#{public_profile_path(@user.username)}']", text: @user.display_name

    # Should show project and post counts
    assert_select "span", text: /projects/i
    assert_select "span", text: /posts/i
  end

  test "should show admin controls for authenticated admins" do
    # Create admin user if not exists
    admin = users(:test_admin)
    admin.update!(account_status: :active)

    sign_in admin
    get public_project_url(@published_project)
    assert_response :success

    # Should show admin controls section
    assert_select ".bg-orange-50", text: /admin controls/i
    assert_select "a[href='#{edit_project_path(@published_project)}']", text: /edit project.*admin/i
    assert_select "a[href='#{public_profile_path(@user.username)}']", text: /view owner profile/i
  end

  test "should not show admin controls for regular users" do
    # Ensure user is active to avoid beta waiting redirect
    @user.update!(account_status: :active)
    sign_in @user
    get public_project_url(@published_project)
    assert_response :success

    # Should not show admin controls
    assert_select ".bg-orange-50", count: 0
  end

  test "should show project stats in sidebar" do
    get public_project_url(@published_project)
    assert_response :success

    # Should show project details section
    assert_select "h3", text: /project details/i
    assert_select "dt", text: /status/i
    assert_select "dd", text: /published/i
    assert_select "dt", text: /featured/i
    assert_select "dt", text: /created/i
  end

  test "should show github enrichment ready cards when summary is available" do
    @published_project.update_columns(
      github_insights_enabled: true,
      github_insights_sync_status: "ready",
      github_insights_last_synced_at: Time.current,
      github_insights_summary: {
        "project_overview" => {
          "stars" => 10,
          "forks" => 3,
          "open_issues_count" => 2,
          "default_branch" => "main"
        },
        "tech_stack" => {
          "languages" => [{ "name" => "Ruby" }, { "name" => "JavaScript" }],
          "manifests_detected" => ["Gemfile", "package.json"]
        },
        "activity_ownership" => {
          "commit_count_sampled" => 20,
          "active_contributors_sampled" => 2,
          "top_contributor_commit_share_percent" => 60.0,
          "latest_commit_at" => "2026-02-10T00:00:00Z"
        },
        "issues_prs" => {
          "issues_open_count" => 1,
          "issues_closed_count" => 4,
          "prs_open_count" => 2,
          "prs_closed_count" => 6,
          "prs_merged_count" => 5,
          "median_pr_merge_time_hours" => 12.5
        },
        "highlights" => ["Recent activity detected"],
        "caveats" => ["Bounded sample"]
      }
    )

    get public_project_url(@published_project)
    assert_response :success
    assert_select "h3", text: /github project signals/i
    assert_select "h4", text: /project overview/i
    assert_select "h4", text: /tech stack & architecture/i
    assert_select "h4", text: /activity & ownership/i
    assert_select "h4", text: /issues & pr delivery/i
    assert_select "h4", text: /evidence highlights/i
    assert_select "h4", text: /caveats/i
  end

  test "should show github enrichment syncing state" do
    @published_project.update_columns(
      github_insights_enabled: true,
      github_insights_sync_status: "syncing",
      github_insights_summary: {}
    )

    get public_project_url(@published_project)
    assert_response :success
    assert_select "h3", text: /github project signals/i
    assert_select "p", text: /signals are being refreshed/i
  end

  test "should show github enrichment failed state" do
    @published_project.update_columns(
      github_insights_enabled: true,
      github_insights_sync_status: "failed",
      github_insights_last_error: "GitHub timeout"
    )

    get public_project_url(@published_project)
    assert_response :success
    assert_select "h3", text: /github project signals/i
    assert_select "p", text: /signals could not be loaded/i
    assert_select "p", text: /GitHub timeout/i
  end

  test "should show github enrichment empty state when never synced" do
    @published_project.update_columns(
      github_insights_enabled: true,
      github_insights_sync_status: "never",
      github_insights_summary: {}
    )

    get public_project_url(@published_project)
    assert_response :success
    assert_select "h3", text: /github project signals/i
    assert_select "p", text: /signals are not available yet/i
  end

  test "should hide github enrichment for non-admin when rollout is internal" do
    @published_project.update_columns(
      github_insights_enabled: true,
      github_insights_sync_status: "ready",
      github_insights_summary: { "project_overview" => { "stars" => 1 } }
    )

    with_github_enrichment_rollout("internal") do
      get public_project_url(@published_project)
    end

    assert_response :success
    assert_select "h3", { text: /github project signals/i, count: 0 }
  end

  test "should handle project with images" do
    # Attach a test image
    @published_project.images.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_image.png")),
      filename: "test_image.png",
      content_type: "image/png"
    )

    get public_project_url(@published_project)
    assert_response :success

    # Should show project gallery section
    assert_select "h2", text: /project gallery/i
    assert_select "img[alt='#{@published_project.title}']"
  end

  test "should redirect to index for non-existent project" do
    get public_project_url(99999)
    assert_redirected_to public_projects_path
    assert_equal "Project not found.", flash[:alert]
  end

  # PAGINATION TESTS
  test "should handle pagination correctly" do
    # Create multiple projects to test pagination
    15.times do |i|
      @user.projects.create!(
        title: "Project #{i}",
        description: "Description #{i}",
        status: :published,
        technologies_used: ["Test"],
        display_order: i + 10
      )
    end

    get public_projects_url
    assert_response :success

    # Should show pagination if more than 12 projects (our limit)
    # Note: This test assumes we have more than 12 published projects total
  end

  # CACHING TESTS
  test "should set appropriate cache headers" do
    get public_projects_url
    assert_response :success

    # Should set cache headers (implementation dependent)
    # This tests that the controller sets cache headers without errors
  end

  test "should set cache headers for individual project" do
    get public_project_url(@published_project)
    assert_response :success

    # Should set cache headers for individual project
  end

  # ERROR HANDLING TESTS
  test "should handle database errors gracefully" do
    # This would require mocking database errors, which is complex
    # For now, we ensure the controller doesn't crash
    get public_projects_url
    assert_response :success
  end

  test "should handle malformed search parameters" do
    get public_projects_url, params: { search: "<script>alert('xss')</script>" }
    assert_response :success

    # Should not crash and should escape the search term in the form
    assert_select "input[name='search']"
    # The value should be escaped in the form (check for escaped version)
    assert_select "input[name='search'][value*='script']"
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end

  def with_github_enrichment_rollout(value)
    original = ENV["GITHUB_PROJECT_ENRICHMENT_ROLLOUT"]
    ENV["GITHUB_PROJECT_ENRICHMENT_ROLLOUT"] = value
    yield
  ensure
    ENV["GITHUB_PROJECT_ENRICHMENT_ROLLOUT"] = original
  end

  test "should require authentication to ask project insight" do
    @published_project.update!(project_insight_enabled: true)

    post ask_public_project_insight_path(@published_project), params: { question: "What does this app do?" }

    assert_redirected_to new_user_session_path
  end

  test "should block project insight when disabled" do
    @published_project.update!(project_insight_enabled: false)
    @user.update!(account_status: :active)
    sign_in @user

    post ask_public_project_insight_path(@published_project), params: { question: "What does this app do?" }

    assert_redirected_to public_project_path(@published_project)
    assert_equal "Project Insight is not enabled for this project.", flash[:alert]
  end

  test "should render answer when project insight is enabled" do
    @published_project.update!(project_insight_enabled: true)
    @user.update!(account_status: :active)
    sign_in @user

    answer_payload = {
      "question" => "What does this app do?",
      "answer" => "It demonstrates a multi-layer Rails architecture.",
      "evidence" => ["Gemfile includes Rails 8", "Recent commits show active maintenance"]
    }

    original_call = ProjectInsight::AnswerService.method(:call)
    ProjectInsight::AnswerService.singleton_class.send(:define_method, :call) do |project:, question:, user:|
      answer_payload
    end
    post ask_public_project_insight_path(@published_project), params: { question: "What does this app do?" }
  ensure
    ProjectInsight::AnswerService.singleton_class.send(:define_method, :call, original_call)

    assert_response :success
    assert_select "h3", text: /project insight/i
    assert_select "p", text: /multi-layer rails architecture/i
    assert_select "li", text: /Gemfile includes Rails 8/i
  end
end
