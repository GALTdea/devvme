require "test_helper"

class UserWelcomeMailerTest < ActionMailer::TestCase
  def setup
    # Set default URL options for testing
    ActionMailer::Base.default_url_options[:host] = 'test.host'
  end
  test "welcome_notification" do
    # Create a test user
    user = users(:test_user_one)

    # Create the email
    email = UserWelcomeMailer.welcome_notification(user)

    # Test that the email was created
    assert_emails 1 do
      email.deliver_now
    end

    # Test the email properties
    assert_equal [user.email], email.to
    assert_equal I18n.t("user_welcome_mailer.welcome_notification.subject"), email.subject
    assert_equal "noreply@devv.me", email.from.first

    # Test the email body contains expected content
    assert_match user.display_name, email.body.encoded
    assert_match "Welcome to DevV.me!", email.body.encoded
    assert_match "pending activation", email.body.encoded
    assert_match "devv.me/#{user.username}", email.body.encoded

    # Test that URLs are included
    assert_match "dashboard", email.body.encoded
    assert_match user.username, email.body.encoded
  end

  test "welcome_notification with different user" do
    # Create another test user
    user = users(:test_user_two)

    # Create the email
    email = UserWelcomeMailer.welcome_notification(user)

    # Test the email properties
    assert_equal [user.email], email.to
    assert_equal I18n.t("user_welcome_mailer.welcome_notification.subject"), email.subject

    # Test the email body contains user-specific content
    assert_match user.display_name, email.body.encoded
    assert_match "devv.me/#{user.username}", email.body.encoded
  end

  test "welcome_notification subject line" do
    user = users(:test_user_one)
    email = UserWelcomeMailer.welcome_notification(user)

    # Test that the subject line is properly internationalized
    assert_equal "Welcome to DevV.me! 🚀", email.subject
  end

  test "welcome_notification email format" do
    user = users(:test_user_one)
    email = UserWelcomeMailer.welcome_notification(user)

    # Test that both HTML and text parts are present
    assert_equal 2, email.parts.length

    # Find HTML and text parts
    html_part = email.parts.find { |part| part.content_type.include?("text/html") }
    text_part = email.parts.find { |part| part.content_type.include?("text/plain") }

    assert_not_nil html_part
    assert_not_nil text_part

    # Test HTML content
    assert_match "<h1>🚀 Welcome to DevV.me!</h1>", html_part.body.encoded
    assert_match user.display_name, html_part.body.encoded

    # Test text content
    assert_match "🚀 Welcome to DevV.me!", text_part.body.encoded
    assert_match user.display_name, text_part.body.encoded
  end

  test "welcome_notification with nil user" do
    # Test that the mailer handles nil user gracefully
    assert_raises(NoMethodError) do
      UserWelcomeMailer.welcome_notification(nil).deliver_now
    end
  end
end
