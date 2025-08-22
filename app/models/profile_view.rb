class ProfileView < ApplicationRecord
  belongs_to :user

  validates :visited_at, presence: true
  validates :visitor_ip, presence: true

  scope :recent, -> { order(visited_at: :desc) }
  scope :today, -> { where(visited_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(visited_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(visited_at: 1.month.ago..Time.current) }
  scope :unique_visitors, -> { distinct.count(:visitor_ip) }

  # Group views by date for analytics
  scope :by_date, ->(start_date = 30.days.ago, end_date = Time.current) {
    where(visited_at: start_date..end_date)
      .group("DATE(visited_at)")
      .order("DATE(visited_at)")
  }

  # Parse browser information from user agent
  def browser_info
    return "Unknown" if user_agent.blank?

    case user_agent.downcase
    when /chrome/
      "Chrome"
    when /firefox/
      "Firefox"
    when /safari/
      "Safari"
    when /edge/
      "Edge"
    when /opera/
      "Opera"
    else
      "Other"
    end
  end

  # Parse device type from user agent
  def device_type
    return "Unknown" if user_agent.blank?

    case user_agent.downcase
    when /mobile|android|iphone|ipad/
      "Mobile"
    when /tablet|ipad/
      "Tablet"
    else
      "Desktop"
    end
  end

  # Check if this is a bot/crawler
  def bot?
    return false if user_agent.blank?

    user_agent.downcase.match?(/bot|crawler|spider|scraper|facebookexternalhit|twitterbot|linkedinbot/)
  end

  # Get referrer domain
  def referrer_domain
    return nil if referrer.blank?

    begin
      URI.parse(referrer).host
    rescue URI::InvalidURIError
      nil
    end
  end
end
