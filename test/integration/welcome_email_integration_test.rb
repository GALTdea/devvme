require "test_helper"

class WelcomeEmailIntegrationTest < ActionDispatch::IntegrationTest
  test "welcome email is sent after successful registration" do
    # Test data
    user_params = {
      user: {
        email: "newuser@example.com",
        username: "newuser",
        full_name: "New User",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    # Assert that an email will be sent
    assert_emails 1 do
      post user_registration_path, params: user_params
    end

    # Should redirect after successful registration
    assert_redirected_to complete_profile_registration_path

    # Follow the redirect to the complete profile page
    follow_redirect!
    # After following redirect, should get success response
    assert_response :success

    # Verify the user was created
    user = User.find_by(email: "newuser@example.com")
    assert_not_nil user
    assert_equal "pending_activation", user.account_status

    # Check the last email sent
    last_email = ActionMailer::Base.deliveries.last
    assert_equal "Welcome to DevV.me! 🚀", last_email.subject
    assert_equal ["newuser@example.com"], last_email.to
    assert_equal "noreply@devv.me", last_email.from.first
    assert_match "New User", last_email.body.encoded
    assert_match "devv.me/newuser", last_email.body.encoded
  end

  test "welcome email is not sent on failed registration" do
    # Test data with invalid password confirmation
    user_params = {
      user: {
        email: "newuser@example.com",
        username: "newuser",
        full_name: "New User",
        password: "password123",
        password_confirmation: "different_password"
      }
    }

    # Assert that no email will be sent
    assert_emails 0 do
      post user_registration_path, params: user_params
    end

    # Verify the user was not created
    user = User.find_by(email: "newuser@example.com")
    assert_nil user
  end

  test "welcome email contains correct URLs" do
    # Test data
    user_params = {
      user: {
        email: "urluser@example.com",
        username: "urluser",
        full_name: "URL User",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    # Send registration request
    assert_emails 1 do
      post user_registration_path, params: user_params
    end

    # Check the email content
    last_email = ActionMailer::Base.deliveries.last
    assert_match "dashboard", last_email.body.encoded
    assert_match "urluser", last_email.body.encoded
  end
end
