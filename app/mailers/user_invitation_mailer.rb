class UserInvitationMailer < ApplicationMailer
  layout false # Disable layout since our template is self-contained

  # Track email delivery status
  after_action :track_email_delivery

  def invitation_notification(user, admin = nil)
    @user = user
    @admin = admin
    @admin_name = @admin&.display_name || "Devv.me Team"
    
    # Build URLs with proper host configuration
    @profile_url = build_profile_url(@user.username)
    @claim_url = build_claim_url(@user.invitation_token)
    
    # Calculate invitation expiry
    sent_at = @user.invitation_sent_at || Time.current
    @expires_at = sent_at + 30.days
    @days_remaining = (@expires_at.to_date - Date.current).to_i
    
    # Profile completion data for preview
    @profile_completion = calculate_profile_completion
    
    # Email metadata for tracking
    @email_type = 'invitation_notification'
    @tracking_id = generate_tracking_id
    
    mail(
      to: @user.email,
      subject: build_subject,
      reply_to: 'noreply@devv.me',
      headers: {
        'X-Mailer-Type' => 'invitation',
        'X-User-ID' => @user.id.to_s,
        'X-Admin-ID' => @admin&.id&.to_s,
        'X-Tracking-ID' => @tracking_id
      }
    )
  end

  def invitation_reminder(user, admin = nil)
    @user = user
    @admin = admin
    @admin_name = @admin&.display_name || "Devv.me Team"
    
    @profile_url = build_profile_url(@user.username)
    @claim_url = build_claim_url(@user.invitation_token)
    
    sent_at = @user.invitation_sent_at || Time.current
    @expires_at = sent_at + 30.days
    @days_remaining = (@expires_at.to_date - Date.current).to_i
    
    @email_type = 'invitation_reminder'
    @tracking_id = generate_tracking_id
    
    mail(
      to: @user.email,
      subject: "⏰ Reminder: Your Devv.me profile invitation expires in #{@days_remaining} days",
      reply_to: 'noreply@devv.me',
      headers: {
        'X-Mailer-Type' => 'invitation_reminder',
        'X-User-ID' => @user.id.to_s,
        'X-Admin-ID' => @admin&.id&.to_s,
        'X-Tracking-ID' => @tracking_id
      }
    )
  end

  def invitation_expired(user, admin = nil)
    @user = user
    @admin = admin
    @admin_name = @admin&.display_name || "Devv.me Team"
    
    @profile_url = build_profile_url(@user.username)
    @support_url = "mailto:support@devv.me?subject=Expired Profile Invitation - #{@user.username}"
    
    @email_type = 'invitation_expired'
    @tracking_id = generate_tracking_id
    
    mail(
      to: @user.email,
      subject: "❌ Your Devv.me profile invitation has expired",
      reply_to: 'noreply@devv.me',
      headers: {
        'X-Mailer-Type' => 'invitation_expired',
        'X-User-ID' => @user.id.to_s,
        'X-Admin-ID' => @admin&.id&.to_s,
        'X-Tracking-ID' => @tracking_id
      }
    )
  end

  private

  def build_profile_url(username)
    host = Rails.application.config.action_mailer.default_url_options[:host]
    protocol = Rails.application.config.action_mailer.default_url_options[:protocol] || 'https'
    "#{protocol}://#{host}/#{username}"
  end

  def build_claim_url(invitation_token)
    host = Rails.application.config.action_mailer.default_url_options[:host]
    protocol = Rails.application.config.action_mailer.default_url_options[:protocol] || 'https'
    "#{protocol}://#{host}/invitations/#{invitation_token}/claim"
  end

  def build_subject
    case @days_remaining
    when 0..3
      "🚨 URGENT: Your Devv.me profile invitation expires in #{@days_remaining} days!"
    when 4..7
      "⏰ Your Devv.me profile invitation expires soon (#{@days_remaining} days left)"
    else
      "🚀 You've been invited to join Devv.me - Your profile is ready!"
    end
  end

  def calculate_profile_completion
    return {} unless @user
    
    completion_data = {
      percentage: @user.profile_completion_percentage,
      completed_fields: [],
      missing_fields: []
    }
    
    # Check which fields are completed
    fields_to_check = {
      'Basic Info' => [@user.full_name, @user.bio, @user.headline].compact,
      'Professional' => [@user.job_title, @user.location].compact,
      'Skills' => @user.skills&.any? ? ['skills'] : [],
      'Social Links' => [@user.github_url, @user.linkedin_url, @user.website_url, @user.twitter_url].compact,
      'Contact' => [@user.contact_email, @user.phone].compact
    }
    
    fields_to_check.each do |category, values|
      if values.any?
        completion_data[:completed_fields] << category
      else
        completion_data[:missing_fields] << category
      end
    end
    
    completion_data
  end

  def generate_tracking_id
    "#{@email_type}_#{@user.id}_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
  end

  def track_email_delivery
    return unless @user && @tracking_id
    
    begin
      # Log email delivery attempt
      Rails.logger.info "Email delivery: #{@email_type} sent to #{@user.email} (User ID: #{@user.id}, Tracking ID: #{@tracking_id})"
      
      # Update user's invitation tracking if this is an invitation email
      if @email_type == 'invitation_notification'
        @user.update_column(:invitation_sent_at, Time.current)
      end
      
    rescue => e
      Rails.logger.error "Failed to track email delivery: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
