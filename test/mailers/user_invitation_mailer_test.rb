require "test_helper"

class UserInvitationMailerTest < ActionMailer::TestCase
  setup do
    @invited_user = users(:invited_user)
    @admin = users(:test_admin)
    @invited_user.invite!(admin: @admin, send_email: false) # Ensure fresh token
  end

  test "invitation_notification email" do
    email = UserInvitationMailer.invitation_notification(@invited_user, @admin)

    assert_emails 1 do
      email.deliver_now
    end

    # Test email headers
    assert_equal [@invited_user.email], email.to
    assert_equal ["noreply@devv.me"], email.reply_to
    assert_match(/You've been invited to join Devv.me/, email.subject)

    # Test custom headers
    assert_equal 'invitation', email['X-Mailer-Type']&.value
    assert_equal @invited_user.id.to_s, email['X-User-ID']&.value
    assert_equal @admin.id.to_s, email['X-Admin-ID']&.value
    assert email['X-Tracking-ID']&.value&.present?

    # Test email body content
    assert_match @invited_user.display_name, email.html_part.body.to_s
    assert_match @invited_user.username, email.html_part.body.to_s
    assert_match @admin.display_name, email.html_part.body.to_s

    # Test verify URL is present (new security flow)
    verify_url = "invitations/#{@invited_user.invitation_token}/verify"
    assert_match verify_url, email.html_part.body.to_s
    assert_match verify_url, email.text_part.body.to_s

    # Test access code is present
    assert_match @invited_user.invitation_access_code, email.html_part.body.to_s
    assert_match @invited_user.invitation_access_code, email.text_part.body.to_s

    # Test security-related content
    assert_match(/access code/i, email.html_part.body.to_s)
    assert_match(/verify/i, email.html_part.body.to_s)

    # Test profile URL is present
    assert_match @invited_user.username, email.html_part.body.to_s
    assert_match @invited_user.username, email.text_part.body.to_s

    # Test urgency indicators based on days remaining
    days_remaining = ((@invited_user.invitation_sent_at + 30.days).to_date - Date.current).to_i
    if days_remaining <= 7
      assert_match(/Time Sensitive|expires/, email.html_part.body.to_s)
    end
  end

  test "invitation_reminder email" do
    email = UserInvitationMailer.invitation_reminder(@invited_user, @admin)

    assert_emails 1 do
      email.deliver_now
    end

    # Test email headers
    assert_equal [@invited_user.email], email.to
    assert_match(/Reminder.*expires/, email.subject)
    assert_equal 'invitation_reminder', email['X-Mailer-Type']&.value

    # Test reminder-specific content
    assert_match(/reminder/i, email.html_part.body.to_s)
    assert_match(/expires/i, email.html_part.body.to_s)
    assert_match(/don't wait/i, email.html_part.body.to_s)

    # Test countdown timer content
    days_remaining = ((@invited_user.invitation_sent_at + 30.days).to_date - Date.current).to_i
    assert_match days_remaining.to_s, email.html_part.body.to_s
  end

  test "invitation_expired email" do
    email = UserInvitationMailer.invitation_expired(@invited_user, @admin)

    assert_emails 1 do
      email.deliver_now
    end

    # Test email headers
    assert_equal [@invited_user.email], email.to
    assert_match(/expired/, email.subject)
    assert_equal 'invitation_expired', email['X-Mailer-Type']&.value

    # Test expired-specific content
    assert_match(/expired/i, email.html_part.body.to_s)
    assert_match(/contact.*support/i, email.html_part.body.to_s)
    assert_match(/don't worry/i, email.html_part.body.to_s)

    # Test support URL is present
    support_url = "mailto:support@devv.me"
    assert_match support_url, email.html_part.body.to_s
  end

  test "email includes profile completion data" do
    # Add some profile data to test completion calculation
    @invited_user.update!(
      bio: "Test bio",
      job_title: "Developer",
      skills: ["Ruby", "Rails"]
    )

    email = UserInvitationMailer.invitation_notification(@invited_user, @admin)
    email.deliver_now

    # Test that profile completion percentage is shown
    assert_match(/\d+%/, email.html_part.body.to_s)
    assert_match(/Complete/, email.html_part.body.to_s)

    # Test that skills are shown
    assert_match("Ruby", email.html_part.body.to_s)
    assert_match("Rails", email.html_part.body.to_s)
  end

  test "email subject changes based on urgency" do
    # Test normal invitation (not urgent)
    @invited_user.update_column(:invitation_sent_at, 5.days.ago)
    email = UserInvitationMailer.invitation_notification(@invited_user, @admin)
    assert_match(/You've been invited/, email.subject)

    # Test urgent invitation (7 days or less)
    @invited_user.update_column(:invitation_sent_at, 25.days.ago)
    email = UserInvitationMailer.invitation_notification(@invited_user, @admin)
    assert_match(/expires soon/, email.subject)

    # Test very urgent invitation (3 days or less)
    @invited_user.update_column(:invitation_sent_at, 28.days.ago)
    email = UserInvitationMailer.invitation_notification(@invited_user, @admin)
    assert_match(/URGENT/, email.subject)
  end

  test "email works without admin" do
    email = UserInvitationMailer.invitation_notification(@invited_user, nil)
    email.deliver_now

    # Should default to "Devv.me Team"
    assert_match("Devv.me Team", email.html_part.body.to_s)
    assert_match("Devv.me Team", email.text_part.body.to_s)

    # Should not have admin ID header
    assert_nil email['X-Admin-ID']&.value
  end

  test "email includes tracking pixel" do
    email = UserInvitationMailer.invitation_notification(@invited_user, @admin)
    email.deliver_now

    # Test that tracking pixel is present
    assert_match(/tracking-pixel/, email.html_part.body.to_s)
    assert_match(/data:image\/gif/, email.html_part.body.to_s)
  end

  test "email includes social proof" do
    email = UserInvitationMailer.invitation_notification(@invited_user, @admin)
    email.deliver_now

    # Test social proof content
    assert_match(/1,000\+ developers/, email.html_part.body.to_s)
    assert_match(/Join.*developers/, email.text_part.body.to_s)
  end

  test "email is mobile responsive" do
    email = UserInvitationMailer.invitation_notification(@invited_user, @admin)
    email.deliver_now

    # Test that mobile-responsive CSS is present
    assert_match(/@media.*max-width.*600px/, email.html_part.body.to_s)
    assert_match(/email-container/, email.html_part.body.to_s)
  end

  test "email includes proper expiration information" do
    email = UserInvitationMailer.invitation_notification(@invited_user, @admin)
    email.deliver_now

    # Test that expiration date is shown
    expires_at = @invited_user.invitation_sent_at + 30.days
    formatted_date = expires_at.strftime("%B %d, %Y")
    assert_match(formatted_date, email.html_part.body.to_s)
    assert_match(formatted_date, email.text_part.body.to_s)
  end

  test "email handles missing fields gracefully" do
    # Test with user without email - this will cause issues in the mailer
    user_without_email = User.new(
      username: "test",
      account_status: :invited,
      invitation_token: "test_token_123",
      invitation_access_code: "123456",
      invitation_sent_at: Time.current
    )

    # The mailer should handle missing invitation_sent_at gracefully
    # but will fail on missing email during delivery
    assert_raises(ArgumentError) do
      UserInvitationMailer.invitation_notification(user_without_email, @admin).deliver_now
    end
  end

  test "email includes access code security notice" do
    email = UserInvitationMailer.invitation_notification(@invited_user, @admin)
    email.deliver_now

    # Test that security notice is present
    assert_match(/Security Protected/i, email.html_part.body.to_s)
    assert_match(/Keep.*private/i, email.html_part.body.to_s)
    assert_match(/6-digit/i, email.text_part.body.to_s)
  end
end
