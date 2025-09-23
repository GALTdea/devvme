require "test_helper"

class RegistrationDisabledTest < ActionDispatch::IntegrationTest
  def setup
    # Ensure we're in production environment for testing
    @original_env = Rails.env
    Rails.env = "production"
  end

  def teardown
    # Restore original environment
    Rails.env = @original_env
    ENV.delete("DISABLE_REGISTRATION")
  end

  test "registration is disabled when DISABLE_REGISTRATION environment variable is set" do
    # Set the environment variable to disable registration
    ENV["DISABLE_REGISTRATION"] = "true"

    # Try to access the registration page
    get new_user_registration_path

    # Should render the registration disabled page instead of the form
    assert_response :success
    assert_select "h2", text: "Registration Temporarily Disabled"
    assert_select "p", text: /We're preparing for an exciting new phase/
  end

  test "registration is enabled when DISABLE_REGISTRATION environment variable is not set" do
    # Ensure the environment variable is not set
    ENV.delete("DISABLE_REGISTRATION")

    # Try to access the registration page
    get new_user_registration_path

    # Should render the normal registration form
    assert_response :success
    assert_select "h2", text: "Sign up"
    assert_select "form[action='#{user_registration_path}']"
  end

  test "registration is enabled when DISABLE_REGISTRATION is blank" do
    # Set the environment variable to blank/empty
    ENV["DISABLE_REGISTRATION"] = ""

    # Try to access the registration page
    get new_user_registration_path

    # Should render the normal registration form
    assert_response :success
    assert_select "h2", text: "Sign up"
    assert_select "form[action='#{user_registration_path}']"
  end

  test "registration is always enabled in non-production environments" do
    # Set environment to development
    Rails.env = "development"
    ENV["DISABLE_REGISTRATION"] = "true"

    # Try to access the registration page
    get new_user_registration_path

    # Should render the normal registration form even with DISABLE_REGISTRATION set
    assert_response :success
    assert_select "h2", text: "Sign up"
    assert_select "form[action='#{user_registration_path}']"
  end

  test "POST to registration is blocked when disabled" do
    ENV["DISABLE_REGISTRATION"] = "true"

    user_attributes = {
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "testuser",
      full_name: "Test User"
    }

    # Try to POST to registration
    post user_registration_path, params: { user: user_attributes }

    # Should render the registration disabled page
    assert_response :success
    assert_select "h2", text: "Registration Temporarily Disabled"

    # Should not create a user
    assert_not User.exists?(email: user_attributes[:email])
  end

  test "navigation shows disabled state when registration is disabled" do
    ENV["DISABLE_REGISTRATION"] = "true"

    # Visit home page
    get root_path

    # Should show "Coming Soon" instead of "Start Building"
    assert_response :success
    assert_select "a[title='Registration temporarily disabled']", text: "Coming Soon"
  end

  test "navigation shows enabled state when registration is enabled" do
    ENV.delete("DISABLE_REGISTRATION")

    # Visit home page
    get root_path

    # Should show normal registration button
    assert_response :success
    assert_select "a[href='#{new_user_registration_path}']", text: "Start Creating"
  end
end
