namespace :invitations do
  desc "Generate access codes for existing invited users without one"
  task generate_missing_access_codes: :environment do
    puts "Generating access codes for invited users without one..."

    users_updated = 0

    User.where(account_status: :invited)
        .where(invitation_access_code: nil)
        .find_each do |user|
      # Generate and save access code
      user.send(:generate_invitation_access_code)
      user.save(validate: false)
      users_updated += 1

      puts "  ✓ Generated code for #{user.username} (#{user.email})"
    end

    puts "\n✓ Done! Generated access codes for #{users_updated} user(s)."
  end

  desc "Resend invitation emails with access codes"
  task resend_with_access_codes: :environment do
    puts "Resending invitation emails with access codes..."

    users_sent = 0

    User.where(account_status: :invited)
        .where.not(invitation_token: nil)
        .find_each do |user|
      # Make sure user has an access code
      if user.invitation_access_code.blank?
        user.send(:generate_invitation_access_code)
        user.save(validate: false)
      end

      # Resend invitation email
      begin
        InvitationEmailService.send_invitation(user)
        users_sent += 1
        puts "  ✓ Sent to #{user.username} (#{user.email})"
      rescue => e
        puts "  ✗ Failed to send to #{user.username}: #{e.message}"
      end
    end

    puts "\n✓ Done! Resent invitations to #{users_sent} user(s)."
  end
end
