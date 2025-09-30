namespace :invitations do
  desc "Send reminder emails to users with expiring invitations"
  task send_reminders: :environment do
    puts "Sending reminder emails for expiring invitations..."

    # Send reminders 7 days before expiry
    result = InvitationEmailService.send_reminder_batch(7)
    puts "7-day reminders: #{result[:success]} sent, #{result[:failed]} failed"

    # Send urgent reminders 3 days before expiry
    result = InvitationEmailService.send_reminder_batch(3)
    puts "3-day reminders: #{result[:success]} sent, #{result[:failed]} failed"

    # Send final reminders 1 day before expiry
    result = InvitationEmailService.send_reminder_batch(1)
    puts "1-day reminders: #{result[:success]} sent, #{result[:failed]} failed"

    puts "Reminder email task completed."
  end

  desc "Send expired notices to users with expired invitations"
  task send_expired_notices: :environment do
    puts "Sending expired notices..."

    result = InvitationEmailService.send_expired_batch
    puts "Expired notices: #{result[:success]} sent, #{result[:failed]} failed"

    puts "Expired notice task completed."
  end

  desc "Clean up old expired invitations (older than 60 days)"
  task cleanup_expired: :environment do
    puts "Cleaning up old expired invitations..."

    # Find users with invitations older than 60 days
    old_expired_users = User.invited
                           .where('invitation_sent_at IS NOT NULL')
                           .where('invitation_sent_at <= ?', 60.days.ago)

    count = old_expired_users.count
    puts "Found #{count} old expired invitations to clean up"

    if count > 0
      # You might want to:
      # 1. Change their status to something like 'invitation_expired'
      # 2. Clear their invitation tokens
      # 3. Send a final notification
      # 4. Archive their data

      old_expired_users.find_each do |user|
        user.update!(
          invitation_token: nil,
          invitation_sent_at: nil,
          # Could add an 'invitation_expired' status if you extend the enum
        )
        puts "Cleaned up expired invitation for #{user.email}"
      end
    end

    puts "Cleanup task completed."
  end

  desc "Show invitation statistics"
  task stats: :environment do
    puts "\n=== Invitation Statistics ==="

    total_invited = User.invited.count
    puts "Total invited users: #{total_invited}"

    pending_invitations = User.invited
                             .where('invitation_sent_at IS NOT NULL')
                             .where('invitation_sent_at > ?', 30.days.ago)
                             .count
    puts "Pending invitations (not expired): #{pending_invitations}"

    expired_invitations = User.invited
                             .where('invitation_sent_at IS NOT NULL')
                             .where('invitation_sent_at <= ?', 30.days.ago)
                             .count
    puts "Expired invitations: #{expired_invitations}"

    # Expiring soon (within 7 days)
    expiring_soon = User.invited
                       .where('invitation_sent_at IS NOT NULL')
                       .where('invitation_sent_at <= ? AND invitation_sent_at > ?',
                              23.days.ago, 30.days.ago)
                       .count
    puts "Expiring within 7 days: #{expiring_soon}"

    # Expiring very soon (within 3 days)
    expiring_very_soon = User.invited
                            .where('invitation_sent_at IS NOT NULL')
                            .where('invitation_sent_at <= ? AND invitation_sent_at > ?',
                                   27.days.ago, 30.days.ago)
                            .count
    puts "Expiring within 3 days: #{expiring_very_soon}"

    # Never sent invitation email
    never_sent = User.invited.where(invitation_sent_at: nil).count
    puts "Invitations never sent: #{never_sent}"

    puts "\n=== Recent Activity ==="

    # Invitations sent in last 24 hours
    recent_invitations = User.invited
                            .where('invitation_sent_at >= ?', 24.hours.ago)
                            .count
    puts "Invitations sent in last 24 hours: #{recent_invitations}"

    # Invitations sent in last week
    weekly_invitations = User.invited
                            .where('invitation_sent_at >= ?', 1.week.ago)
                            .count
    puts "Invitations sent in last week: #{weekly_invitations}"

    puts "\n=========================="
  end

  desc "Test email delivery for a specific user"
  task :test_email, [:email, :type] => :environment do |t, args|
    email = args[:email]
    email_type = args[:type] || 'invitation'

    unless email
      puts "Usage: rake invitations:test_email[user@example.com,invitation]"
      puts "Email types: invitation, reminder, expired"
      exit 1
    end

    user = User.find_by(email: email)
    unless user
      puts "User not found with email: #{email}"
      exit 1
    end

    unless user.invited?
      puts "User must have 'invited' status to send invitation emails"
      exit 1
    end

    puts "Sending #{email_type} email to #{email}..."

    success = case email_type
    when 'invitation'
      InvitationEmailService.send_invitation(user, nil, deliver_now: true)
    when 'reminder'
      InvitationEmailService.send_reminder(user, nil, deliver_now: true)
    when 'expired'
      InvitationEmailService.send_expired_notice(user, nil, deliver_now: true)
    else
      puts "Invalid email type: #{email_type}"
      exit 1
    end

    if success
      puts "✅ Email sent successfully!"
    else
      puts "❌ Email delivery failed. Check logs for details."
    end
  end

  desc "Resend invitation for a specific user"
  task :resend, [:email] => :environment do |t, args|
    email = args[:email]

    unless email
      puts "Usage: rake invitations:resend[user@example.com]"
      exit 1
    end

    user = User.find_by(email: email)
    unless user
      puts "User not found with email: #{email}"
      exit 1
    end

    unless user.invited?
      puts "User must have 'invited' status to resend invitation"
      exit 1
    end

    puts "Resending invitation to #{email}..."

    # Generate new token and send email
    user.invite!(send_email: false) # Generate new token
    success = InvitationEmailService.send_invitation(user, nil, deliver_now: true)

    if success
      puts "✅ Invitation resent successfully!"
      puts "New claim URL: #{Rails.application.routes.url_helpers.root_url}invitations/#{user.invitation_token}/claim"
    else
      puts "❌ Failed to resend invitation. Check logs for details."
    end
  end
end
