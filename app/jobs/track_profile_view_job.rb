class TrackProfileViewJob < ApplicationJob
  queue_as :default

  # Track profile view with visitor information
  def perform(user_id, visitor_ip, user_agent, referrer)
    user = User.find_by(id: user_id)
    return unless user

    # Don't track views from bots or the user themselves
    return if user_agent.present? && bot?(user_agent)

    # Prevent excessive tracking from the same IP (max 1 per hour)
    recent_view = user.profile_views
                      .where(visitor_ip: visitor_ip)
                      .where("visited_at > ?", 1.hour.ago)
                      .exists?

    return if recent_view

    # Create the profile view record
    user.profile_views.create!(
      visitor_ip: visitor_ip,
      user_agent: user_agent&.truncate(500),
      referrer: referrer&.truncate(500),
      visited_at: Time.current
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to track profile view: #{e.message}"
  end

  private

  def bot?(user_agent)
    return false if user_agent.blank?

    user_agent.downcase.match?(/bot|crawler|spider|scraper|facebookexternalhit|twitterbot|linkedinbot|googlebot|bingbot/)
  end
end
