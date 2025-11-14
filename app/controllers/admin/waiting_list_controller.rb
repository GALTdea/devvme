class Admin::WaitingListController < ApplicationController
  before_action :authenticate_user!
  before_action :set_waiting_list_entry, only: [:show, :approve, :decline]

  include Pagy::Backend

  def index
    authorize [:admin, :waiting_list], :index?, policy_class: Admin::WaitingListPolicy

    @pagy, @waiting_list_entries = pagy(
      WaitingListEntry.includes(:user)
                      .order(params[:sort] || 'created_at DESC'),
      limit: 20
    )

    # Apply filters
    case params[:status]
    when 'pending'
      @waiting_list_entries = @waiting_list_entries.pending
    when 'invited'
      @waiting_list_entries = @waiting_list_entries.invited
    when 'converted'
      @waiting_list_entries = @waiting_list_entries.converted
    when 'declined'
      @waiting_list_entries = @waiting_list_entries.where(status: :declined)
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @waiting_list_entries = @waiting_list_entries.where(
        "email ILIKE ? OR full_name ILIKE ?",
        search_term, search_term
      )
    end

    # Calculate statistics
    @stats = {
      total: WaitingListEntry.count,
      pending: WaitingListEntry.pending.count,
      invited: WaitingListEntry.invited.count,
      converted: WaitingListEntry.converted.count,
      declined: WaitingListEntry.where(status: :declined).count
    }

    log_admin_activity('view_waiting_list')
  end

  def show
    authorize [:admin, @waiting_list_entry], :show?, policy_class: Admin::WaitingListPolicy
    log_admin_activity('view_waiting_list_entry', { entry_id: @waiting_list_entry.id, email: @waiting_list_entry.email })
  end

  def approve
    authorize [:admin, @waiting_list_entry], :approve?, policy_class: Admin::WaitingListPolicy

    begin
      user = @waiting_list_entry.approve_and_invite!(admin: current_user)

      log_admin_activity('approve_waiting_list_entry', {
        entry_id: @waiting_list_entry.id,
        email: @waiting_list_entry.email,
        user_id: user.id,
        username: user.username
      })

      redirect_to admin_waiting_list_index_path,
                  notice: "Successfully approved and invited #{@waiting_list_entry.email}. Invitation email has been sent."
    rescue => e
      Rails.logger.error "Failed to approve waiting list entry: #{e.message}"
      redirect_to admin_waiting_list_path(@waiting_list_entry),
                  alert: "Failed to approve entry: #{e.message}"
    end
  end

  def decline
    authorize [:admin, @waiting_list_entry], :decline?, policy_class: Admin::WaitingListPolicy

    @waiting_list_entry.mark_as_declined!

    log_admin_activity('decline_waiting_list_entry', {
      entry_id: @waiting_list_entry.id,
      email: @waiting_list_entry.email
    })

    redirect_to admin_waiting_list_index_path,
                notice: "Declined waiting list entry for #{@waiting_list_entry.email}."
  end

  private

  def set_waiting_list_entry
    @waiting_list_entry = WaitingListEntry.find(params[:id])
  end

  def log_admin_activity(action, details = {})
    return unless current_user&.can_access_admin?

    AdminActivity.create!(
      admin: current_user,
      action: action,
      details: details,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
