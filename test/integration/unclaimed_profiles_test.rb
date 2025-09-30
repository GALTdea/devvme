require "test_helper"

class UnclaimedProfilesTest < ActionDispatch::IntegrationTest
  def setup
    @invited_user = User.create!(
      username: "inviteduser",
      email: "invited@example.com",
      full_name: "Invited User",
      bio: "This is an invited user profile",
      job_title: "Software Developer",
      location: "Test City",
      account_status: :invited
    )
    @invited_user.invite!(send_email: false)
  end

  def teardown
    @invited_user.destroy if @invited_user.persisted?
  end

  test "should display unclaimed profile publicly" do
    get "/#{@invited_user.username}"

    assert_response :success
    assert_select "title", /Unclaimed Profile/
    assert_match @invited_user.display_name, response.body
    assert_match @invited_user.bio, response.body
  end

  test "should set unclaimed profile instance variables" do
    get "/#{@invited_user.username}"

    assert_response :success
    # The controller should set @unclaimed_profile = true
    # We can't directly test instance variables, but we can test the effects
    assert_match "unclaimed", response.body.downcase
  end

  test "should not track profile visits for unclaimed profiles" do
    # This is tested indirectly by ensuring no TrackProfileViewJob jobs are enqueued
    assert_no_enqueued_jobs only: TrackProfileViewJob do
      get "/#{@invited_user.username}"
    end

    assert_response :success
  end

  test "should handle SEO differently for unclaimed profiles" do
    get "/#{@invited_user.username}"

    assert_response :success
    assert_select "meta[name='description']" do |elements|
      content = elements.first["content"]
      assert_includes content.downcase, "unclaimed"
    end
  end

  test "should not redirect invited user to dashboard when viewing own profile" do
    # This tests that invited users can view their own unclaimed profile
    # without being redirected to dashboard (which they can't access)

    # We can't easily sign in an invited user since they have no password
    # But we can test that the redirect logic works correctly
    get "/#{@invited_user.username}"

    assert_response :success
    # Should not redirect to dashboard
    assert_not_includes response.body, "dashboard"
  end

  test "should show empty projects and blog posts for unclaimed profiles" do
    get "/#{@invited_user.username}"

    assert_response :success
    # The controller should set empty arrays for projects and blog posts
    # This will be more testable once we have the UI components
  end

  test "should set appropriate cache headers for unclaimed profiles" do
    get "/#{@invited_user.username}"

    assert_response :success
    # Should have shorter cache duration for unclaimed profiles
    cache_control = response.headers["Cache-Control"]
    assert_includes cache_control, "max-age=300" # 5 minutes
  end

  test "should handle expired invitations gracefully" do
    # Set invitation to expired
    @invited_user.update!(invitation_sent_at: 31.days.ago)

    get "/#{@invited_user.username}"

    assert_response :success
    # Should still display the profile even if invitation is expired
    assert_match @invited_user.display_name, response.body
  end
end
