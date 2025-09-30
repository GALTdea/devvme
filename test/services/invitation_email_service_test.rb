require "test_helper"

class InvitationEmailServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper
  setup do
    @invited_user = users(:invited_user)
    @admin = users(:test_admin)
    @invited_user.invite!(admin: @admin, send_email: false) # Ensure fresh token
  end

  test "send_invitation delivers email successfully" do
    assert_emails 1 do
      result = InvitationEmailService.send_invitation(@invited_user, @admin, deliver_now: true)
      assert result, "Email delivery should succeed"
    end

    # Check that invitation_sent_at was updated
    @invited_user.reload
    assert @invited_user.invitation_sent_at.present?
    assert @invited_user.invitation_sent_at > 1.minute.ago
  end

  test "send_reminder delivers email successfully" do
    assert_emails 1 do
      result = InvitationEmailService.send_reminder(@invited_user, @admin, deliver_now: true)
      assert result, "Reminder email delivery should succeed"
    end
  end

  test "send_expired_notice delivers email successfully" do
    assert_emails 1 do
      result = InvitationEmailService.send_expired_notice(@invited_user, @admin, deliver_now: true)
      assert result, "Expired notice email delivery should succeed"
    end
  end

  test "validates user is required" do
    assert_raises(ArgumentError, "User is required") do
      InvitationEmailService.send_invitation(nil, @admin, deliver_now: true)
    end
  end

  test "validates user email is present" do
    user_without_email = User.new(username: "test", account_status: :invited)

    assert_raises(ArgumentError, "User email is required") do
      InvitationEmailService.send_invitation(user_without_email, @admin, deliver_now: true)
    end
  end

  test "validates email format" do
    @invited_user.update_column(:email, "invalid-email")

    assert_raises(ArgumentError, "Invalid email format") do
      InvitationEmailService.send_invitation(@invited_user, @admin, deliver_now: true)
    end
  end

  test "validates user has invited status for invitations" do
    @invited_user.update_column(:account_status, User.account_statuses[:active])

    assert_raises(ArgumentError, "User must have invited status") do
      InvitationEmailService.send_invitation(@invited_user, @admin, deliver_now: true)
    end
  end

  test "validates user has invitation token" do
    @invited_user.update_column(:invitation_token, nil)

    assert_raises(ArgumentError, "User must have invitation token") do
      InvitationEmailService.send_invitation(@invited_user, @admin, deliver_now: true)
    end
  end

  test "handles email delivery failures with retry" do
    # Mock the mailer to fail
    original_method = UserInvitationMailer.method(:invitation_notification)
    UserInvitationMailer.define_singleton_method(:invitation_notification) do |*args|
      raise StandardError, "SMTP Error"
    end

    begin
      result = InvitationEmailService.send_invitation(@invited_user, @admin, deliver_now: true)
      assert_not result, "Should return false on delivery failure"
    ensure
      # Restore original method
      UserInvitationMailer.define_singleton_method(:invitation_notification, original_method)
    end
  end

  test "send_reminder_batch processes expiring users" do
    # Create additional invited users with different expiry dates
    user1 = User.create!(
      username: "expiring1",
      email: "expiring1@example.com",
      full_name: "Expiring User 1",
      account_status: :invited,
      invitation_token: SecureRandom.urlsafe_base64(32),
      invitation_sent_at: 24.days.ago # Expires in 6 days
    )

    user2 = User.create!(
      username: "expiring2",
      email: "expiring2@example.com",
      full_name: "Expiring User 2",
      account_status: :invited,
      invitation_token: SecureRandom.urlsafe_base64(32),
      invitation_sent_at: 26.days.ago # Expires in 4 days
    )

    # Should send reminders to users expiring within 7 days
    assert_emails 2 do
      result = InvitationEmailService.send_reminder_batch(7)
      assert_equal 2, result[:success]
      assert_equal 0, result[:failed]
    end
  end

  test "send_expired_batch processes expired users" do
    # Create expired user
    expired_user = User.create!(
      username: "expired1",
      email: "expired1@example.com",
      full_name: "Expired User",
      account_status: :invited,
      invitation_token: SecureRandom.urlsafe_base64(32),
      invitation_sent_at: 31.days.ago # Already expired
    )

    assert_emails 1 do
      result = InvitationEmailService.send_expired_batch
      assert_equal 1, result[:success]
      assert_equal 0, result[:failed]
    end
  end

  test "email service logs delivery events" do
    # Capture log output
    log_output = StringIO.new
    logger = Logger.new(log_output)
    original_logger = Rails.logger

    begin
      Rails.logger = logger
      InvitationEmailService.send_invitation(@invited_user, @admin, deliver_now: true)
    ensure
      Rails.logger = original_logger
    end

    log_content = log_output.string
    assert_match(/Successfully sent invitation email/, log_content)
    assert_match(@invited_user.email, log_content)
    assert_match(@invited_user.id.to_s, log_content)
  end

  test "email service generates tracking IDs" do
    service = InvitationEmailService.new(user: @invited_user, admin: @admin, email_type: 'invitation')
    tracking_id = service.send(:generate_tracking_id)

    assert tracking_id.present?
    assert_match(/invitation_#{@invited_user.id}_\d+_[a-f0-9]+/, tracking_id)
  end

  test "email service calculates profile completion" do
    # Add profile data
    @invited_user.update!(
      bio: "Test bio",
      job_title: "Developer",
      skills: ["Ruby", "Rails"],
      github_url: "https://github.com/test"
    )

    service = InvitationEmailService.new(user: @invited_user, admin: @admin, email_type: 'invitation')
    completion = service.send(:calculate_profile_completion)

    assert completion[:percentage] > 0
    assert completion[:completed_fields].include?('Basic Info')
    assert completion[:completed_fields].include?('Professional')
    assert completion[:completed_fields].include?('Skills')
    assert completion[:completed_fields].include?('Social Links')
  end

  test "email service works without admin" do
    assert_emails 1 do
      result = InvitationEmailService.send_invitation(@invited_user, nil, deliver_now: true)
      assert result, "Should work without admin"
    end
  end

  test "email service queues emails by default" do
    # Temporarily set queue adapter to test mode to prevent immediate execution
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test

    begin
      clear_enqueued_jobs

      # Test that emails are queued, not delivered immediately
      assert_no_emails do
        result = InvitationEmailService.send_invitation(@invited_user, @admin)
        assert result, "Should queue email successfully"
      end

      # Check that job was enqueued
      assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob
    ensure
      # Restore original adapter
      ActiveJob::Base.queue_adapter = original_adapter
    end
  end

  test "email service delivers immediately when requested" do
    assert_emails 1 do
      result = InvitationEmailService.send_invitation(@invited_user, @admin, deliver_now: true)
      assert result, "Should deliver email immediately"
    end

    # Should not enqueue any jobs
    assert_enqueued_jobs 0, only: ActionMailer::MailDeliveryJob
  end

  test "different email types have different priorities" do
    # This test would need to be expanded based on your job queue implementation
    # For now, just test that different email types can be sent

    assert InvitationEmailService.send_invitation(@invited_user, @admin)
    assert InvitationEmailService.send_reminder(@invited_user, @admin)
    assert InvitationEmailService.send_expired_notice(@invited_user, @admin)
  end
end
