class InvitationAnalyticsService
  def initialize(time_range = '30_days')
    @time_range = time_range
    @start_date = calculate_start_date
    @end_date = Time.current
  end

  def call
    {
      overview: overview_metrics,
      trends: invitation_trends,
      conversion: conversion_metrics,
      status_breakdown: status_breakdown,
      performance: performance_metrics,
      recent_activity: recent_activity
    }
  end

  private

  def calculate_start_date
    case @time_range
    when '7_days'
      7.days.ago
    when '30_days'
      30.days.ago
    when '90_days'
      90.days.ago
    when '1_year'
      1.year.ago
    else
      30.days.ago
    end
  end

  def overview_metrics
    invited_users = User.where(account_status: :invited)

    {
      total_invitations: invited_users.count,
      pending_invitations: invited_users.select(&:invitation_pending?).count,
      expired_invitations: invited_users.select(&:invitation_expired?).count,
      claimed_invitations: User.where(account_status: :active)
                              .where('invitation_accepted_at IS NOT NULL')
                              .where(invitation_accepted_at: @start_date..@end_date)
                              .count,
      conversion_rate: calculate_overall_conversion_rate,
      average_claim_time: calculate_average_claim_time
    }
  end

  def invitation_trends
    # Group invitations by day/week/month based on time range
    group_by = case @time_range
               when '7_days'
                 'day'
               when '30_days'
                 'day'
               when '90_days'
                 'week'
               else
                 'month'
               end

    invitations_sent = User.where(account_status: [:invited, :active])
                          .where(invitation_sent_at: @start_date..@end_date)
                          .group_by_period(group_by.to_sym, :invitation_sent_at)
                          .count

    invitations_claimed = User.where(account_status: :active)
                             .where('invitation_accepted_at IS NOT NULL')
                             .where(invitation_accepted_at: @start_date..@end_date)
                             .group_by_period(group_by.to_sym, :invitation_accepted_at)
                             .count

    {
      sent: invitations_sent,
      claimed: invitations_claimed,
      group_by: group_by
    }
  end

  def conversion_metrics
    total_sent = User.where(account_status: [:invited, :active])
                    .where(invitation_sent_at: @start_date..@end_date)
                    .count

    total_claimed = User.where(account_status: :active)
                       .where('invitation_accepted_at IS NOT NULL')
                       .where(invitation_accepted_at: @start_date..@end_date)
                       .count

    conversion_rate = total_sent > 0 ? (total_claimed.to_f / total_sent * 100).round(2) : 0

    # Conversion by time periods
    conversion_by_period = calculate_conversion_by_period

    {
      total_sent: total_sent,
      total_claimed: total_claimed,
      conversion_rate: conversion_rate,
      by_period: conversion_by_period,
      benchmark: 65.0 # Industry benchmark for invitation conversion
    }
  end

  def status_breakdown
    invited_users = User.where(account_status: :invited)

    {
      pending: invited_users.select(&:invitation_pending?).count,
      expired: invited_users.select(&:invitation_expired?).count,
      recent: invited_users.where('invitation_sent_at > ?', 7.days.ago).count,
      old: invited_users.where('invitation_sent_at < ?', 30.days.ago).count
    }
  end

  def performance_metrics
    # Email delivery success rate (based on logs)
    total_attempts = AdminActivity.where(action: 'create_invited_user')
                                 .where(created_at: @start_date..@end_date)
                                 .count

    successful_deliveries = AdminActivity.where(action: 'create_invited_user')
                                        .where(created_at: @start_date..@end_date)
                                        .where("details->>'invitation_sent' = 'true'")
                                        .count

    delivery_rate = total_attempts > 0 ? (successful_deliveries.to_f / total_attempts * 100).round(2) : 0

    # Average time to claim
    avg_claim_time = calculate_average_claim_time

    # Most common failure reasons
    failure_reasons = analyze_failure_reasons

    {
      delivery_rate: delivery_rate,
      total_attempts: total_attempts,
      successful_deliveries: successful_deliveries,
      average_claim_time_hours: avg_claim_time,
      failure_reasons: failure_reasons
    }
  end

  def recent_activity
    AdminActivity.where(action: ['create_invited_user', 'resend_invitation', 'bulk_create_invitations_csv', 'bulk_create_invitations_manual'])
                 .where(created_at: @start_date..@end_date)
                 .includes(:admin, :target)
                 .order(created_at: :desc)
                 .limit(20)
                 .map do |activity|
      {
        id: activity.id,
        action: activity.action,
        admin_name: activity.admin&.display_name || 'System',
        target_name: activity.target&.display_name || activity.details['username'],
        created_at: activity.created_at,
        details: activity.details
      }
    end
  end

  def calculate_overall_conversion_rate
    total_invitations = User.where(account_status: [:invited, :active])
                           .where('invitation_sent_at IS NOT NULL')
                           .count

    claimed_invitations = User.where(account_status: :active)
                             .where('invitation_accepted_at IS NOT NULL')
                             .count

    return 0 if total_invitations == 0
    (claimed_invitations.to_f / total_invitations * 100).round(2)
  end

  def calculate_average_claim_time
    claimed_users = User.where(account_status: :active)
                       .where('invitation_sent_at IS NOT NULL')
                       .where('invitation_accepted_at IS NOT NULL')
                       .where(invitation_accepted_at: @start_date..@end_date)

    return 0 if claimed_users.empty?

    total_hours = claimed_users.sum do |user|
      (user.invitation_accepted_at - user.invitation_sent_at) / 1.hour
    end

    (total_hours / claimed_users.count).round(2)
  end

  def calculate_conversion_by_period
    # Calculate conversion rate for different time periods
    periods = {
      '24_hours' => 24.hours.ago,
      '7_days' => 7.days.ago,
      '30_days' => 30.days.ago
    }

    periods.map do |period_name, start_time|
      sent = User.where(account_status: [:invited, :active])
                .where(invitation_sent_at: start_time..@end_date)
                .count

      claimed = User.where(account_status: :active)
                   .where('invitation_accepted_at IS NOT NULL')
                   .where(invitation_accepted_at: start_time..@end_date)
                   .count

      rate = sent > 0 ? (claimed.to_f / sent * 100).round(2) : 0

      {
        period: period_name,
        sent: sent,
        claimed: claimed,
        rate: rate
      }
    end
  end

  def analyze_failure_reasons
    # Analyze common patterns in failed invitations
    expired_invitations = User.where(account_status: :invited)
                             .select(&:invitation_expired?)

    reasons = {
      'Expired (>30 days)' => expired_invitations.count,
      'Invalid email domains' => count_invalid_email_domains,
      'Duplicate emails' => count_duplicate_email_attempts,
      'Validation errors' => count_validation_errors
    }

    reasons.sort_by { |_, count| -count }.first(5)
  end

  def count_invalid_email_domains
    # Count invitations to potentially invalid domains
    invalid_domains = ['example.com', 'test.com', 'localhost']
    User.where(account_status: :invited)
        .where('email ILIKE ANY (ARRAY[?])', invalid_domains.map { |d| "%@#{d}" })
        .count
  end

  def count_duplicate_email_attempts
    # Count attempts to invite existing users
    AdminActivity.where(action: 'create_invited_user')
                 .where(created_at: @start_date..@end_date)
                 .where("details->>'error' ILIKE '%already exists%'")
                 .count
  end

  def count_validation_errors
    # Count validation errors during invitation creation
    AdminActivity.where(action: 'create_invited_user')
                 .where(created_at: @start_date..@end_date)
                 .where("details->>'error' IS NOT NULL")
                 .count
  end
end
