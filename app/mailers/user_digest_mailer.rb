class UserDigestMailer < ApplicationMailer
  layout false # Disable layout since our template is self-contained

  # Track email delivery status
  after_action :track_email_delivery

  def weekly_digest(user, digest_data)
    @user = user
    @digest_data = digest_data
    @digest_preference = user.digest_preference_or_create
    @total_content_count = calculate_total_content_count

    # Build URLs
    @profile_url = build_profile_url(@user.username)
    @preferences_url = build_preferences_url
    @unsubscribe_url = build_unsubscribe_url

    # Email metadata
    @email_type = 'weekly_digest'
    @tracking_id = generate_tracking_id

    mail(
      to: @user.email,
      subject: build_subject,
      reply_to: 'noreply@devv.me',
      'X-Mailer-Type' => 'digest',
      'X-User-ID' => @user.id.to_s,
      'X-Tracking-ID' => @tracking_id
    )
  end

  def daily_digest(user, digest_data)
    @user = user
    @digest_data = digest_data
    @digest_preference = user.digest_preference_or_create
    @total_content_count = calculate_total_content_count

    # Build URLs
    @profile_url = build_profile_url(@user.username)
    @preferences_url = build_preferences_url
    @unsubscribe_url = build_unsubscribe_url

    # Email metadata
    @email_type = 'daily_digest'
    @tracking_id = generate_tracking_id

    mail(
      to: @user.email,
      subject: build_subject,
      reply_to: 'noreply@devv.me',
      'X-Mailer-Type' => 'digest',
      'X-User-ID' => @user.id.to_s,
      'X-Tracking-ID' => @tracking_id
    )
  end

  def monthly_digest(user, digest_data)
    @user = user
    @digest_data = digest_data
    @digest_preference = user.digest_preference_or_create
    @total_content_count = calculate_total_content_count

    # Build URLs
    @profile_url = build_profile_url(@user.username)
    @preferences_url = build_preferences_url
    @unsubscribe_url = build_unsubscribe_url

    # Email metadata
    @email_type = 'monthly_digest'
    @tracking_id = generate_tracking_id

    mail(
      to: @user.email,
      subject: build_subject,
      reply_to: 'noreply@devv.me',
      'X-Mailer-Type' => 'digest',
      'X-User-ID' => @user.id.to_s,
      'X-Tracking-ID' => @tracking_id
    )
  end

  private

  def build_subject
    frequency = @digest_preference.frequency
    content_count = @total_content_count

    case frequency
    when 'daily'
      if content_count > 0
        "#{content_count} new update#{'s' if content_count != 1} from developers you follow"
      else
        "Your daily Devv.me digest"
      end
    when 'weekly'
      if content_count > 0
        "#{content_count} new update#{'s' if content_count != 1} this week from developers you follow"
      else
        "Your weekly Devv.me digest"
      end
    when 'monthly'
      if content_count > 0
        "#{content_count} new update#{'s' if content_count != 1} this month from developers you follow"
      else
        "Your monthly Devv.me digest"
      end
    else
      "Your Devv.me digest"
    end
  end

  def calculate_total_content_count
    total = 0
    @digest_data.each_value do |user_content|
      total += user_content[:blog_posts].count
      total += user_content[:projects].count
      total += user_content[:profile_updates].count
    end
    total
  end

  def build_profile_url(username)
    "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/#{username}"
  end

  def build_preferences_url
    "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/digest_preferences"
  end

  def build_unsubscribe_url
    token = generate_unsubscribe_token
    "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/digest_preferences/unsubscribe?token=#{token}"
  end

  def generate_unsubscribe_token
    # Generate a signed token for unsubscribe security
    Rails.application.message_verifier('digest_unsubscribe').generate(@user.id)
  end

  def generate_tracking_id
    "#{@user.id}-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
  end

  def track_email_delivery
    Rails.logger.info "Digest email sent to #{@user.email} (User ID: #{@user.id}, Type: #{@email_type})"
  end
end
