require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      username: "testuser",
      full_name: "Test User",
      bio: "I'm a test user",
      github_url: "https://github.com/testuser",
      linkedin_url: "https://linkedin.com/in/testuser",
      website_url: "https://testuser.com",
      account_status: :active
    )
  end

  test "should redirect to sign in when not authenticated" do
    get profile_path
    assert_redirected_to new_user_session_path
  end

  # Show profile tests
  test "should show profile when authenticated" do
    sign_in @user
    get profile_path
    assert_response :success

    # Should display user information
    assert_select "p", text: /@#{@user.username}/
    assert_select "h1", text: /#{@user.full_name}/
    assert_select "p", text: /#{@user.bio}/
  end

  test "should display social links on profile" do
    sign_in @user
    get profile_path
    assert_response :success

    # Should show social media links
    assert_select "a[href='#{@user.github_url}']"
    assert_select "a[href='#{@user.linkedin_url}']"
    assert_select "a[href='#{@user.website_url}']"
  end

  test "should display profile completion percentage" do
    sign_in @user
    get profile_path
    assert_response :success

    # Should show profile completion
    completion_percentage = @user.profile_completion_percentage
    assert_select "dd", text: /#{completion_percentage}%/
  end

  test "should display edit profile link" do
    sign_in @user
    get profile_path
    assert_response :success

    # Should have edit profile link
    assert_select "a[href='#{edit_profile_path}']", text: /Edit Profile/
  end

  test "should display share profile button with correct data attributes" do
    skip "Feature not yet implemented - would test share profile button functionality"
    # sign_in @user
    # get profile_path
    # assert_response :success

    # # Should have share button with Stimulus controller
    # assert_select "div[data-controller='share-button']"
    # assert_select "button[data-action='click->share-button#share']", text: /Share Profile/

    # # Should have correct data attributes
    # assert_select "div[data-share-button-title-value='#{@user.display_name}\\'s Profile']"
  end

  # Edit profile tests
  test "should show edit profile form when authenticated" do
    sign_in @user
    get edit_profile_path
    assert_response :success

    # Should display edit form
    assert_select "form[action='#{profile_path}']"
    assert_select "input[name='user[username]'][value='#{@user.username}']"
    assert_select "input[name='user[full_name]'][value='#{@user.full_name}']"
    assert_select "textarea[name='user[bio]']", text: @user.bio
    assert_select "input[name='user[github_url]'][value='#{@user.github_url}']"
    assert_select "input[name='user[linkedin_url]'][value='#{@user.linkedin_url}']"
    assert_select "input[name='user[website_url]'][value='#{@user.website_url}']"
  end

  test "should show avatar upload field in edit form" do
    sign_in @user
    get edit_profile_path
    assert_response :success

    # Should have avatar upload field
    assert_select "input[name='user[avatar]'][type='file']"
  end

  # Update profile tests
  test "should update profile with valid attributes" do
    sign_in @user

    new_attributes = {
      username: "newusername",
      full_name: "New Full Name",
      bio: "New bio description",
      github_url: "https://github.com/newusername",
      linkedin_url: "https://linkedin.com/in/newusername",
      website_url: "https://newusername.com"
    }

    patch profile_path, params: { user: new_attributes }

    # Should redirect to profile page
    assert_redirected_to profile_path
    follow_redirect!

    # Should show success message
    assert_select "#alert-success", text: /Profile updated successfully/

    # Should update user attributes
    @user.reload
    assert_equal new_attributes[:username], @user.username
    assert_equal new_attributes[:full_name], @user.full_name
    assert_equal new_attributes[:bio], @user.bio
    assert_equal new_attributes[:github_url], @user.github_url
    assert_equal new_attributes[:linkedin_url], @user.linkedin_url
    assert_equal new_attributes[:website_url], @user.website_url
  end

  test "should normalize URLs when updating profile" do
    sign_in @user

    patch profile_path, params: {
      user: {
        github_url: "github.com/user",
        linkedin_url: "linkedin.com/in/user",
        website_url: "example.com"
      }
    }

    assert_redirected_to profile_path

    @user.reload
    assert_equal "https://github.com/user", @user.github_url
    assert_equal "https://linkedin.com/in/user", @user.linkedin_url
    assert_equal "https://example.com", @user.website_url
  end

  test "should not update profile with invalid username" do
    sign_in @user

    patch profile_path, params: {
      user: { username: "ab" } # Too short
    }

    # Should render edit form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{profile_path}']"

    # Should show error message
    assert_select "#alert-danger, .error-message", text: /Username is too short/

    # Should not update user
    @user.reload
    assert_equal "testuser", @user.username
  end

  test "should not update profile with invalid URL" do
    sign_in @user

    patch profile_path, params: {
      user: { github_url: "not-a-valid-url" }
    }

    # Should render edit form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{profile_path}']"

    # Should show error message
    assert_select "#alert-danger, .error-message", text: /Github url must be a valid URL/

    # Should not update user
    @user.reload
    assert_equal "https://github.com/testuser", @user.github_url
  end

  test "should not update profile with existing username" do
    # Create another user
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      username: "otherusername"
    )

    sign_in @user

    patch profile_path, params: {
      user: { username: "otherusername" }
    }

    # Should render edit form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{profile_path}']"

    # Should show error message
    assert_select "#alert-danger, .error-message", text: /Username has already been taken/

    # Should not update user
    @user.reload
    assert_equal "testuser", @user.username
  end

  test "should allow updating with same username (case change)" do
    sign_in @user

    patch profile_path, params: {
      user: { username: "TestUser" } # Same username with different case
    }

    # Should redirect successfully
    assert_redirected_to profile_path

    # Should update username
    @user.reload
    assert_equal "TestUser", @user.username
  end

  test "should handle maximum length validations" do
    sign_in @user

    # debugger

    patch profile_path, params: {
      user: {
        full_name: "a" * 101, # Too long
        bio: "b" * 501 # Too long
      }
    }

    # Should render edit form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{profile_path}']"

    # Should show error messages
    assert_select "#alert-danger, .error-message", text: /Full name is too long/
    assert_select "#alert-danger, .error-message", text: /Bio is too long/
  end

  test "should allow clearing optional fields" do
    sign_in @user

    patch profile_path, params: {
      user: {
        full_name: "",
        bio: "",
        github_url: "",
        linkedin_url: "",
        website_url: ""
      }
    }

    # Should redirect successfully
    assert_redirected_to profile_path

    # Should clear fields
    @user.reload
    assert_equal "", @user.full_name
    assert_equal "", @user.bio
    assert_equal "", @user.github_url
    assert_equal "", @user.linkedin_url
    assert_equal "", @user.website_url
  end

  test "should not allow updating email through profile update" do
    sign_in @user

    patch profile_path, params: {
      user: { email: "newemail@example.com" }
    }

    # Email should not be updated (strong parameters protection)
    @user.reload
    assert_equal "test@example.com", @user.email
  end

  test "should not allow updating password through profile update" do
    sign_in @user
    original_encrypted_password = @user.encrypted_password

    patch profile_path, params: {
      user: { password: "newpassword123" }
    }

    # Password should not be updated (strong parameters protection)
    @user.reload
    assert_equal original_encrypted_password, @user.encrypted_password
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
