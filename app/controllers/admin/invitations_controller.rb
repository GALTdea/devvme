class Admin::InvitationsController < ApplicationController
  before_action :authenticate_user!

  include Pagy::Backend

  def index
    authorize [:admin, :invitation], :index?, policy_class: Admin::InvitationPolicy

    @pagy, @invitations = pagy(
      User.where(account_status: :invited)
          .includes(:admin_activities)
          .order(params[:sort] || 'invitation_sent_at DESC'),
      limit: 20
    )

    # Apply filters
    case params[:status]
    when 'pending'
      @invitations = @invitations.select(&:invitation_pending?)
    when 'expired'
      @invitations = @invitations.select(&:invitation_expired?)
    when 'recent'
      @invitations = @invitations.where('invitation_sent_at > ?', 7.days.ago)
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @invitations = @invitations.where(
        "username ILIKE ? OR full_name ILIKE ? OR email ILIKE ?",
        search_term, search_term, search_term
      )
    end

    # Calculate statistics
    @stats = calculate_invitation_stats
  end

  def analytics
    authorize [:admin, :invitation], :analytics?, policy_class: Admin::InvitationPolicy

    @time_range = params[:time_range] || '30_days'
    @analytics_data = InvitationAnalyticsService.new(@time_range).call
  end

  def bulk_resend
    authorize [:admin, :invitation], :bulk_resend?, policy_class: Admin::InvitationPolicy

    user_ids = params[:user_ids] || []
    resent_count = 0
    failed_count = 0

    user_ids.each do |user_id|
      user = User.find(user_id)
      if user&.invited? && user.invitation_pending?
        if user.invite!(admin: current_user, send_email: true)
          resent_count += 1
        else
          failed_count += 1
        end
      end
    end

    log_admin_activity('bulk_resend_invitations', {
      resent_count: resent_count,
      failed_count: failed_count,
      user_ids: user_ids
    })

    if failed_count > 0
      redirect_to admin_invitations_path, notice: "#{resent_count} invitations resent successfully. #{failed_count} failed to resend."
    else
      redirect_to admin_invitations_path, notice: "#{resent_count} invitations resent successfully."
    end
  end

  def bulk_expire
    authorize [:admin, :invitation], :bulk_expire?, policy_class: Admin::InvitationPolicy

    user_ids = params[:user_ids] || []
    expired_count = 0

    user_ids.each do |user_id|
      user = User.find(user_id)
      if user&.invited?
        # Set invitation as expired by backdating the sent_at time
        user.update_column(:invitation_sent_at, 31.days.ago)
        expired_count += 1
      end
    end

    log_admin_activity('bulk_expire_invitations', {
      expired_count: expired_count,
      user_ids: user_ids
    })

    redirect_to admin_invitations_path, notice: "#{expired_count} invitations have been expired."
  end

  def cleanup_expired
    authorize [:admin, :invitation], :cleanup?, policy_class: Admin::InvitationPolicy

    expired_invitations = User.where(account_status: :invited)
                             .where('invitation_sent_at < ?', 30.days.ago)

    cleanup_count = expired_invitations.count

    # Option 1: Delete expired invitations
    if params[:action_type] == 'delete'
      expired_invitations.destroy_all
      message = "#{cleanup_count} expired invitations have been deleted."

    # Option 2: Send expiration notices
    elsif params[:action_type] == 'notify'
      expired_invitations.find_each do |user|
        UserInvitationMailer.invitation_expired(user, current_user).deliver_later
      end
      message = "Expiration notices sent to #{cleanup_count} users."

    # Option 3: Convert to deactivated status
    else
      expired_invitations.update_all(account_status: :deactivated)
      message = "#{cleanup_count} expired invitations converted to deactivated status."
    end

    log_admin_activity('cleanup_expired_invitations', {
      action_type: params[:action_type] || 'deactivate',
      affected_count: cleanup_count
    })

    redirect_to admin_invitations_path, notice: message
  end

  def bulk_create
    authorize [:admin, :invitation], :bulk_create?, policy_class: Admin::InvitationPolicy

    if request.post?
      process_bulk_creation
    else
      # Show the bulk creation form
      render :bulk_create
    end
  end

  private

  def process_bulk_creation
    if params[:csv_file].present?
      process_csv_upload
    elsif params[:manual_entries].present?
      process_manual_entries
    else
      redirect_to bulk_create_admin_invitations_path, alert: "Please provide either a CSV file or manual entries."
    end
  end

  def process_csv_upload
    csv_file = params[:csv_file]

    begin
      results = BulkInvitationService.new(current_user).process_csv(csv_file)

      log_admin_activity('bulk_create_invitations_csv', {
        total_processed: results[:total],
        successful: results[:successful],
        failed: results[:failed],
        filename: csv_file.original_filename
      })

      if results[:failed] > 0
        redirect_to admin_invitations_path,
                   notice: "#{results[:successful]} invitations created successfully. #{results[:failed]} failed.",
                   alert: "Some invitations failed to create. Check the logs for details."
      else
        redirect_to admin_invitations_path,
                   notice: "#{results[:successful]} invitations created and sent successfully!"
      end
    rescue => e
      Rails.logger.error "Bulk invitation CSV processing failed: #{e.message}"
      redirect_to bulk_create_admin_invitations_path,
                 alert: "Failed to process CSV file: #{e.message}"
    end
  end

  def process_manual_entries
    entries = params[:manual_entries].split("\n").map(&:strip).reject(&:blank?)

    begin
      results = BulkInvitationService.new(current_user).process_manual_entries(entries)

      log_admin_activity('bulk_create_invitations_manual', {
        total_processed: results[:total],
        successful: results[:successful],
        failed: results[:failed]
      })

      if results[:failed] > 0
        redirect_to admin_invitations_path,
                   notice: "#{results[:successful]} invitations created successfully. #{results[:failed]} failed."
      else
        redirect_to admin_invitations_path,
                   notice: "#{results[:successful]} invitations created and sent successfully!"
      end
    rescue => e
      Rails.logger.error "Bulk invitation manual processing failed: #{e.message}"
      redirect_to bulk_create_admin_invitations_path,
                 alert: "Failed to process entries: #{e.message}"
    end
  end

  def calculate_invitation_stats
    invited_users = User.where(account_status: :invited)

    {
      total_invitations: invited_users.count,
      pending_invitations: invited_users.select(&:invitation_pending?).count,
      expired_invitations: invited_users.select(&:invitation_expired?).count,
      recent_invitations: invited_users.where('invitation_sent_at > ?', 7.days.ago).count,
      conversion_rate: calculate_conversion_rate
    }
  end

  def calculate_conversion_rate
    total_invitations_sent = AdminActivity.where(action: 'create_invited_user').count
    total_claimed = AdminActivity.where(action: 'invitation_claimed').count

    return 0 if total_invitations_sent == 0
    ((total_claimed.to_f / total_invitations_sent) * 100).round(1)
  end

  def log_admin_activity(action, details = {})
    AdminActivity.create!(
      admin: current_user,
      action: action,
      details: details,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
