class LimitedAccessController < ApplicationController
  # Skip the pending activation check for this controller since we're handling limited access
  skip_before_action :check_pending_activation, only: [:pending_activation, :suspended, :deactivated]

  def pending_activation
    # Only allow pending activation users to access this page
    redirect_to dashboard_path unless user_signed_in? && current_user.pending_activation?
  end

  def suspended
    # Only allow suspended users to access this page
    redirect_to dashboard_path unless user_signed_in? && current_user.suspended?
  end

  def deactivated
    # Only allow deactivated users to access this page
    redirect_to dashboard_path unless user_signed_in? && current_user.account_status == 'deactivated'
  end

  private

  # Helper method to get the appropriate limited access page based on user status
  def limited_access_page_for(user)
    return nil unless user

    case user.account_status
    when 'pending_activation'
      pending_activation_path
    when 'suspended'
      suspended_path
    when 'deactivated'
      deactivated_path
    else
      nil
    end
  end

  # Helper method to get user-friendly status message
  def status_message_for(user)
    return nil unless user

    case user.account_status
    when 'pending_activation'
      "Your account is pending activation by an administrator."
    when 'suspended'
      "Your account has been suspended. Reason: #{user.suspension_reason || 'No reason provided'}"
    when 'deactivated'
      "Your account has been deactivated."
    else
      nil
    end
  end
end
