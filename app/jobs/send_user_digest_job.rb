class SendUserDigestJob < ApplicationJob
  queue_as :mailers

  def perform(user_id, digest_type = "weekly")
    user = User.find(user_id)

    Rails.logger.info "Generating #{digest_type} digest for user #{user.id} (#{user.email})"

    # Generate digest content
    digest_data = DigestGeneratorService.generate_digest_for_user(user)

    # Only send if there's new content or if it's been a long time since last digest
    should_send = digest_data.any? { |_, data| data[:blog_posts].any? || data[:projects].any? || data[:profile_updates].any? }

    # Also send if it's been more than 2 weeks since last digest (to keep users engaged)
    last_sent = user.digest_preference_or_create.last_sent_at
    should_send ||= last_sent.nil? || last_sent < 2.weeks.ago

    if should_send
      # Send the appropriate digest email
      case digest_type
      when "daily"
        UserDigestMailer.daily_digest(user, digest_data).deliver_now
      when "weekly"
        UserDigestMailer.weekly_digest(user, digest_data).deliver_now
      when "monthly"
        UserDigestMailer.monthly_digest(user, digest_data).deliver_now
      else
        UserDigestMailer.weekly_digest(user, digest_data).deliver_now
      end

      # Update user's digest preference
      user.digest_preference_or_create.mark_digest_sent!

      Rails.logger.info "Successfully sent #{digest_type} digest to user #{user.id}"
    else
      # No new content, but still update the next send time
      user.digest_preference_or_create.mark_digest_sent!

      Rails.logger.info "No new content for #{digest_type} digest for user #{user.id}, updated next send time"
    end

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "User #{user_id} not found for digest job: #{e.message}"
  rescue => e
    Rails.logger.error "Failed to send #{digest_type} digest to user #{user_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Don't re-raise the error to prevent job retries that might spam users
    # Instead, log the error and continue
  end
end
