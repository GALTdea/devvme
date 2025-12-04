class Admin::NotificationsController < ApplicationController
  before_action :require_admin

  def index
    @notifications = current_user.notifications.order(created_at: :desc).limit(50)
    @unread_notifications_count = current_user.unread_notifications_count
  end

  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_to admin_notifications_path, notice: "Notification marked as read." }
      format.json { render json: { status: "success" } }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("notification_#{notification.id}") }
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html { redirect_to admin_notifications_path, notice: "All notifications marked as read." }
      format.json { render json: { status: "success" } }
      format.turbo_stream { redirect_to admin_notifications_path }
    end
  end
end
