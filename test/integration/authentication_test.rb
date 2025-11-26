require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    @user_attributes = {
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "testuser",
      full_name: "Test User"
    }
  end

  # Sign up tests
  test "user can sign up with valid attributes" do
    get new_user_registration_path
    assert_response :success
    assert_select "form[action='#{user_registration_path}']"

    post user_registration_path, params: { user: @user_attributes }

    # Should create a new user
    assert User.exists?(email: @user_attributes[:email])

    # Update the newly created user's account status after creation
    user = User.find_by(email: @user_attributes[:email])
    user.update!(account_status: :active)

    # Should redirect to dashboard after successful sign up
    assert_redirected_to dashboard_path
    follow_redirect!

    # Should show success message
    assert_select "#alert-success", text: /Welcome! You have signed up successfully/

    # User should be signed in (check for user dropdown)
    assert_select "li[data-controller='dropdown']"
    assert_select "button[data-action*='dropdown#toggle']"
  end

  test "user cannot sign up with invalid email" do
    @user_attributes[:email] = "invalid-email"

    post user_registration_path, params: { user: @user_attributes }

    # Should not create user
    assert_not User.exists?(email: @user_attributes[:email])

    # Should render the registration form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{user_registration_path}']"

    # Should show error message
    assert_select "#alert-danger, .error-message", text: /Email is invalid/
  end

  test "user cannot sign up with weak password" do
    @user_attributes[:password] = "123"
    @user_attributes[:password_confirmation] = "123"

    post user_registration_path, params: { user: @user_attributes }

    # Should not create user
    assert_not User.exists?(email: @user_attributes[:email])

    # Should render the registration form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{user_registration_path}']"

    # Should show error message
    assert_select "#alert-danger, .error-message", text: /Password is too short/
  end

  test "user cannot sign up with mismatched password confirmation" do
    @user_attributes[:password_confirmation] = "different_password"

    post user_registration_path, params: { user: @user_attributes }

    # Should not create user
    assert_not User.exists?(email: @user_attributes[:email])

    # Should render the registration form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{user_registration_path}']"

    # Should show error message
    assert_select "#alert-danger, .error-message", text: /Password confirmation doesn't match/
  end

  test "user cannot sign up with existing email" do
    # Create a user first
    User.create!(@user_attributes)

    # Try to create another user with same email
    post user_registration_path, params: { user: @user_attributes.merge(username: "differentuser") }

    # Should not create second user
    assert_equal 1, User.where(email: @user_attributes[:email]).count

    # Should render the registration form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{user_registration_path}']"

    # Should show error message
    assert_select "#alert-danger, .error-message", text: /Email has already been taken/
  end

  test "user cannot sign up with existing username" do
    # Create a user first
    User.create!(@user_attributes)

    # Try to create another user with same username
    post user_registration_path, params: {
      user: @user_attributes.merge(email: "different@example.com")
    }

    # Should not create second user
    assert_equal 1, User.where(username: @user_attributes[:username]).count

    # Should render the registration form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{user_registration_path}']"

    # Should show error message
    assert_select "#alert-danger, .error-message", text: /Username has already been taken/
  end

  # Sign in tests
  test "user can sign in with valid credentials" do
    user = User.create!(@user_attributes)
    # Update account status after creation to override the pending_activation callback
    user.update!(account_status: :active)

    get new_user_session_path
    assert_response :success
    assert_select "form[action='#{user_session_path}']"

    post user_session_path, params: {
      user: {
        email: @user_attributes[:email],
        password: @user_attributes[:password]
      }
    }

    # Should redirect to dashboard
    assert_redirected_to dashboard_path
    follow_redirect!

    # Should show success message
    assert_select "#alert-success", text: /Signed in successfully/

    # User should be signed in (check for user dropdown instead of hidden sign out link)
    assert_select "li[data-controller='dropdown']"
    assert_select "button[data-action*='dropdown#toggle']"
    assert_select "h1", text: /Welcome back/ # Dashboard page content
  end

  test "user cannot sign in with invalid email" do
    User.create!(@user_attributes)

    post user_session_path, params: {
      user: {
        email: "wrong@example.com",
        password: @user_attributes[:password]
      }
    }

    # Should render the sign in form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{user_session_path}']"

    # Should show error message (Devise typically uses flash[:alert])
    assert_select "#alert-danger", text: /Invalid Email or password/
  end

  test "user cannot sign in with invalid password" do
    User.create!(@user_attributes)

    post user_session_path, params: {
      user: {
        email: @user_attributes[:email],
        password: "wrongpassword"
      }
    }

    # Should render the sign in form again
    assert_response :unprocessable_entity
    assert_select "form[action='#{user_session_path}']"

    # Should show error message (Devise typically uses flash[:alert])
    assert_select "#alert-danger", text: /Invalid Email or password/
  end

  # Sign out tests
  test "signed in user can sign out" do
    user = User.create!(@user_attributes)
    user.update!(account_status: :active)
    sign_in user

    # Verify user is signed in
    get dashboard_path
    assert_response :success

    # Sign out
    delete destroy_user_session_path

    # Should redirect to home page
    assert_redirected_to root_path
    follow_redirect!

    # Should show success message
    assert_select "#alert-success", text: /Signed out successfully/

    # User should be signed out
    assert_select "a[href='#{new_user_session_path}']", text: /Sign In/
    assert_select "li[data-controller='dropdown']", count: 0
  end

  test "signed out user cannot access protected pages" do
    # Try to access dashboard without being signed in
    get dashboard_path

    # Should redirect to sign in page
    assert_redirected_to new_user_session_path
    follow_redirect!

    # Should show alert message
    assert_select "#alert-danger", text: /You need to sign in or sign up before continuing/
  end

  test "signed in user is redirected from auth pages" do
    user = User.create!(@user_attributes)
    user.update!(account_status: :active)
    sign_in user

    # Try to access sign in page while signed in
    get new_user_session_path
    assert_redirected_to dashboard_path

    # Try to access sign up page while signed in
    get new_user_registration_path
    assert_redirected_to dashboard_path
  end

  # Remember me functionality
  test "user can sign in with remember me" do
    user = User.create!(@user_attributes)
    user.update!(account_status: :active)
    post user_session_path, params: {
      user: {
        email: @user_attributes[:email],
        password: @user_attributes[:password],
        remember_me: "1"
      }
    }

    # Should redirect to dashboard
    assert_redirected_to dashboard_path

    # Should set remember token cookie
    assert_not_nil cookies[:remember_user_token]
  end

  # Password reset tests
  test "user can request password reset" do
    user = User.create!(@user_attributes)

    get new_user_password_path
    assert_response :success
    assert_select "form[action='#{user_password_path}']"

    # Request password reset
    assert_emails 1 do
      post user_password_path, params: {
        user: { email: user.email }
      }
    end

    # Should redirect to sign in page
    assert_redirected_to new_user_session_path
    follow_redirect!

    # Should show success message
    assert_select "#alert-success", text: /You will receive an email with instructions/
  end

  test "password reset request with invalid email shows error message" do
    get new_user_password_path
    assert_response :success

    # Request password reset with non-existent email
    assert_no_emails do
      post user_password_path, params: {
        user: { email: "nonexistent@example.com" }
      }
    end

    # Should render the form again with error (paranoid mode is disabled)
    assert_response :unprocessable_entity
    assert_select "#alert-danger", text: /Email not found/
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
