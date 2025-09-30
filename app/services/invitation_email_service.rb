class InvitationEmailService
  include ActiveModel::Model

  attr_accessor :user, :admin, :email_type

  # Email delivery with error handling and retry logic
  def self.send_invitation(user, admin = nil, options = {})
    new(user: user, admin: admin, email_type: 'invitation').deliver_with_retry(options)
  end

  def self.send_reminder(user, admin = nil, options = {})
    new(user: user, admin: admin, email_type: 'reminder').deliver_with_retry(options)
  end

  def self.send_expired_notice(user, admin = nil, options = {})
    new(user: user, admin: admin, email_type: 'expired').deliver_with_retry(options)
  end

  def initialize(user:, admin: nil, email_type: 'invitation')
    @user = user
    @admin = admin
    @email_type = email_type
    @max_retries = 3
    @retry_delay = 5.seconds
  end

  def deliver_with_retry(options = {})
    retries = 0

    begin
      validate_email_delivery

      case @email_type
      when 'invitation'
        deliver_invitation_email(options)
      when 'reminder'
        deliver_reminder_email(options)
      when 'expired'
        deliver_expired_email(options)
      else
        raise ArgumentError, "Unknown email type: #{@email_type}"
      end

      log_successful_delivery
      true

    rescue => e
      retries += 1

      if retries <= @max_retries
        Rails.logger.warn "Email delivery failed (attempt #{retries}/#{@max_retries}): #{e.message}"
        sleep(@retry_delay * retries) # Exponential backoff
        retry
      else
        handle_delivery_failure(e)
        false
      end
    end
  end

  private

  def validate_email_delivery
    raise ArgumentError, "User is required" unless @user
    raise ArgumentError, "User email is required" unless @user.email.present?
    raise ArgumentError, "User must have invited status for invitations" if @email_type == 'invitation' && !@user.invited?

    # Check if email is valid format
    unless @user.email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      raise ArgumentError, "Invalid email format: #{@user.email}"
    end

    # Check if user has invitation token for invitation/reminder emails
    if ['invitation', 'reminder'].include?(@email_type) && @user.invitation_token.blank?
      raise ArgumentError, "User must have invitation token for #{@email_type} emails"
    end
  end

  def deliver_invitation_email(options = {})
    # Update invitation sent timestamp
    @user.update_column(:invitation_sent_at, Time.current)

    # Send email
    mailer = UserInvitationMailer.invitation_notification(@user, @admin)

    if options[:deliver_now]
      mailer.deliver_now
    else
      mailer.deliver_later(queue: 'mailers', priority: 10)
    end

    # Track delivery
    track_email_event('invitation_sent')
  end

  def deliver_reminder_email(options = {})
    mailer = UserInvitationMailer.invitation_reminder(@user, @admin)

    if options[:deliver_now]
      mailer.deliver_now
    else
      mailer.deliver_later(queue: 'mailers', priority: 5) # Higher priority for reminders
    end

    track_email_event('reminder_sent')
  end

  def deliver_expired_email(options = {})
    mailer = UserInvitationMailer.invitation_expired(@user, @admin)

    if options[:deliver_now]
      mailer.deliver_now
    else
      mailer.deliver_later(queue: 'mailers', priority: 15)
    end

    track_email_event('expired_notice_sent')
  end

  def log_successful_delivery
    Rails.logger.info "Successfully sent #{@email_type} email to #{@user.email} (User ID: #{@user.id})"

    # Update user's email tracking if needed
    case @email_type
    when 'invitation'
      # Already updated invitation_sent_at in deliver_invitation_email
    when 'reminder'
      # Could track last reminder sent timestamp if needed
    when 'expired'
      # Could track expired notice sent if needed
    end
  end

  def handle_delivery_failure(error)
    Rails.logger.error "Failed to send #{@email_type} email to #{@user.email} after #{@max_retries} attempts"
    Rails.logger.error "Error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")

    # Track failure
    track_email_event('delivery_failed', { error: error.message })

    # Notify admins of critical email failures
    if Rails.env.production?
      notify_admin_of_email_failure(error)
    end
  end

  def track_email_event(event_type, metadata = {})
    # This could be expanded to use a proper analytics service
    Rails.logger.info "Email event: #{event_type} for user #{@user.id} (#{@user.email})"

    # Could integrate with services like:
    # - Mixpanel
    # - Segment
    # - Google Analytics
    # - Custom analytics database

    event_data = {
      user_id: @user.id,
      email: @user.email,
      event_type: event_type,
      email_type: @email_type,
      admin_id: @admin&.id,
      timestamp: Time.current,
      metadata: metadata
    }

    # For now, just log it
    Rails.logger.info "Email analytics: #{event_data.to_json}"
  end

  def notify_admin_of_email_failure(error)
    # This could send a notification to admin users or a monitoring service
    # For now, just log it as an error
    Rails.logger.error "ADMIN ALERT: Critical email delivery failure"
    Rails.logger.error "User: #{@user.email} (ID: #{@user.id})"
    Rails.logger.error "Email type: #{@email_type}"
    Rails.logger.error "Error: #{error.message}"

    # Could integrate with:
    # - Slack notifications
    # - PagerDuty
    # - Email to admin team
    # - Dashboard alerts
  end

  # Class methods for batch operations
  def self.send_reminder_batch(days_before_expiry = 7)
    expiring_users = User.invited
                        .where('invitation_sent_at IS NOT NULL')
                        .where('invitation_sent_at <= ?', (30 - days_before_expiry).days.ago)
                        .where('invitation_sent_at > ?', 31.days.ago) # Not already expired

    success_count = 0
    failure_count = 0

    expiring_users.find_each do |user|
      if send_reminder(user)
        success_count += 1
      else
        failure_count += 1
      end
    end

    Rails.logger.info "Reminder batch complete: #{success_count} sent, #{failure_count} failed"
    { success: success_count, failed: failure_count }
  end

  def self.send_expired_batch
    expired_users = User.invited
                       .where('invitation_sent_at IS NOT NULL')
                       .where('invitation_sent_at <= ?', 30.days.ago)

    success_count = 0
    failure_count = 0

    expired_users.find_each do |user|
      if send_expired_notice(user)
        success_count += 1
      else
        failure_count += 1
      end
    end

    Rails.logger.info "Expired notice batch complete: #{success_count} sent, #{failure_count} failed"
    { success: success_count, failed: failure_count }
  end
end
