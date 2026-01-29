# == Schema Information
#
# Table name: user_digest_preferences
#
#  id                      :bigint           not null, primary key
#  digest_time             :time             default(2000-01-01 08:00:00.000000000 UTC +00:00), not null
#  enabled                 :boolean          default(TRUE), not null
#  frequency               :integer          default("weekly"), not null
#  include_blog_posts      :boolean          default(TRUE), not null
#  include_profile_updates :boolean          default(FALSE), not null
#  include_projects        :boolean          default(TRUE), not null
#  last_sent_at            :datetime
#  next_send_at            :datetime
#  timezone                :string           default("UTC"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  user_id                 :bigint           not null
#
# Indexes
#
#  idx_on_frequency_enabled_next_send_at_d7bc4c43b0  (frequency,enabled,next_send_at)
#  index_user_digest_preferences_on_next_send_at     (next_send_at)
#  index_user_digest_preferences_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserDigestPreference < ApplicationRecord
  belongs_to :user

  # Frequency options
  enum :frequency, {
    daily: 0,
    biweekly: 1,
    weekly: 2,
    monthly: 3,
    never: 4
  }, default: :weekly

  # Validations
  validates :frequency, presence: true
  validates :digest_time, presence: true
  validates :timezone, presence: true
  validates :enabled, inclusion: { in: [true, false] }
  validates :include_blog_posts, inclusion: { in: [true, false] }
  validates :include_projects, inclusion: { in: [true, false] }
  validates :include_profile_updates, inclusion: { in: [true, false] }

  # Callbacks
  after_create :set_initial_next_send_at
  after_update :update_next_send_at_if_frequency_changed

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :due_for_digest, -> { where('next_send_at <= ?', Time.current) }
  scope :for_frequency, ->(freq) { where(frequency: freq) }

  # Instance methods
  def should_receive_digest?
    enabled? && frequency != 'never' && next_send_at <= Time.current
  end

  def digest_enabled?
    enabled? && frequency != 'never'
  end

  def time_until_next_digest
    return nil unless digest_enabled?
    next_send_at - Time.current
  end

  def mark_digest_sent!
    update!(
      last_sent_at: Time.current,
      next_send_at: calculate_next_send_time
    )
  end

  def update_frequency!(new_frequency)
    update!(frequency: new_frequency)
  end

  def disable_digests!
    update!(enabled: false, frequency: :never)
  end

  def enable_digests!(frequency = :weekly)
    update!(enabled: true, frequency: frequency)
  end

  private

  def set_initial_next_send_at
    update_column(:next_send_at, calculate_next_send_time)
  end

  def update_next_send_at_if_frequency_changed
    if saved_change_to_frequency? || saved_change_to_enabled?
      update_column(:next_send_at, calculate_next_send_time)
    end
  end

  def calculate_next_send_time
    return nil unless digest_enabled?

    # Get the user's timezone
    user_timezone = timezone.present? ? timezone : 'UTC'

    # Parse the preferred time
    time_parts = digest_time.strftime('%H:%M').split(':')
    hour = time_parts[0].to_i
    minute = time_parts[1].to_i

    # Start from now in user's timezone
    now_in_user_tz = Time.current.in_time_zone(user_timezone)

    # Create the next send time in user's timezone
    case frequency
    when 'daily'
      # Next day at preferred time
      next_send = now_in_user_tz.beginning_of_day + hour.hours + minute.minutes
      next_send += 1.day if next_send <= now_in_user_tz
    when 'weekly'
      # Next Monday at preferred time
      days_until_monday = (1 - now_in_user_tz.wday) % 7
      days_until_monday = 7 if days_until_monday == 0 # If today is Monday, go to next Monday
      next_send = now_in_user_tz.beginning_of_week + days_until_monday.days + hour.hours + minute.minutes
    when 'biweekly'
      # Every other Monday at preferred time
      days_until_monday = (1 - now_in_user_tz.wday) % 7
      days_until_monday = 7 if days_until_monday == 0
      next_send = now_in_user_tz.beginning_of_week + days_until_monday.days + hour.hours + minute.minutes
      # Add 2 weeks for biweekly
      next_send += 2.weeks
    when 'monthly'
      # First Monday of next month at preferred time
      next_month = now_in_user_tz.beginning_of_month + 1.month
      first_monday = next_month.beginning_of_month
      first_monday += (1 - first_monday.wday) % 7 if first_monday.wday != 1
      next_send = first_monday + hour.hours + minute.minutes
    else
      return nil
    end

    # Convert back to UTC for storage
    next_send.utc
  end
end
