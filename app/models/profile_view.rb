# == Schema Information
#
# Table name: profile_views
# Database name: primary
#
#  id         :bigint           not null, primary key
#  referrer   :string(500)
#  user_agent :string(500)
#  visited_at :datetime         not null
#  visitor_ip :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_profile_views_on_user_id                                (user_id)
#  index_profile_views_on_user_id_and_visited_at                 (user_id,visited_at)
#  index_profile_views_on_visited_at                             (visited_at)
#  index_profile_views_on_visitor_ip_and_user_id_and_visited_at  (visitor_ip,user_id,visited_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
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
