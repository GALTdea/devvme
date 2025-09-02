class Admin::UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [:show, :edit, :update, :destroy, :suspend, :unsuspend, :promote, :demote]
  before_action :require_super_admin, only: [:destroy, :bulk_delete, :promote, :demote, :bulk_promote, :bulk_demote]

  include Pagy::Backend

  def index
    @pagy, @users = pagy(
      User.includes(:projects, :blog_posts)
          .order(params[:sort] || 'created_at DESC'),
      limit: 20
    )

    # Apply filters
    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = @users.where.not(suspended_at: nil) if params[:status] == 'suspended'
    @users = @users.where(suspended_at: nil) if params[:status] == 'active'

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where(
        "username ILIKE ? OR full_name ILIKE ? OR email ILIKE ?",
        search_term, search_term, search_term
      )
    end

    @total_users = User.count
    @active_users = User.where(suspended_at: nil).count
    @suspended_users = User.where.not(suspended_at: nil).count
    @admin_users = User.where(role: [:admin, :super_admin]).count
  end

  def show
    @user_activities = @user.admin_activities.recent.limit(10) if @user.can_access_admin?
    @user_stats = {
      projects_count: @user.projects.count,
      published_projects_count: @user.projects.published.count,
      blog_posts_count: @user.blog_posts.count,
      published_blog_posts_count: @user.blog_posts.published_posts.count,
      profile_views: @user.total_profile_views,
      unique_visitors: @user.unique_profile_visitors
    }
  end

  def edit
  end

  def update
    if @user.update(user_params)
      log_admin_activity('update_user', {
        changed_attributes: @user.previous_changes.keys,
        notes: params[:admin_notes]
      })
      redirect_to admin_user_path(@user), notice: 'User updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    username = @user.username
    @user.destroy!
    log_admin_activity('delete_user', { username: username })
    redirect_to admin_users_path, notice: "User '#{username}' has been deleted."
  end

  def suspend
    reason = params[:suspension_reason] || 'Suspended by admin'
    @user.suspend!(reason: reason, admin: current_user)
    redirect_to admin_user_path(@user), notice: 'User has been suspended.'
  end

  def unsuspend
    @user.unsuspend!(admin: current_user)
    redirect_to admin_user_path(@user), notice: 'User has been unsuspended.'
  end

  def promote
    old_role = @user.role
    if @user.update(role: params[:role] || 'admin')
      log_admin_activity('promote_user', {
        old_role: old_role,
        new_role: @user.role,
        target_username: @user.username
      })
      redirect_to admin_user_path(@user), notice: "User promoted to #{@user.role}."
    else
      redirect_to admin_user_path(@user), alert: 'Failed to promote user.'
    end
  end

  def demote
    old_role = @user.role
    @user.update!(role: 'user')
    log_admin_activity('demote_user', {
      old_role: old_role,
      new_role: @user.role,
      target_username: @user.username
    })
    redirect_to admin_user_path(@user), notice: 'User demoted to regular user.'
  end

  def bulk_suspend
    user_ids = params[:user_ids] || []
    reason = params[:suspension_reason] || 'Bulk suspension by admin'

    suspended_count = 0
    user_ids.each do |user_id|
      user = User.find(user_id)
      if user && !user.suspended?
        user.suspend!(reason: reason, admin: current_user)
        suspended_count += 1
      end
    end

    log_admin_activity('bulk_operation', {
      operation: 'bulk_suspend',
      affected_users: suspended_count,
      reason: reason
    })

    redirect_to admin_users_path, notice: "#{suspended_count} users have been suspended."
  end

  def bulk_delete
    user_ids = params[:user_ids] || []

    deleted_count = 0
    deleted_usernames = []
    user_ids.each do |user_id|
      user = User.find(user_id)
      if user && user != current_user
        deleted_usernames << user.username
        user.destroy!
        deleted_count += 1
      end
    end

    log_admin_activity('bulk_operation', {
      operation: 'bulk_delete',
      affected_users: deleted_count,
      usernames: deleted_usernames
    })

    redirect_to admin_users_path, notice: "#{deleted_count} users have been deleted."
  end

  def bulk_promote
    user_ids = params[:user_ids] || []
    role = params[:role] || 'admin'

    promoted_count = 0
    user_ids.each do |user_id|
      user = User.find(user_id)
      if user && user.user?
        user.update!(role: role)
        promoted_count += 1
      end
    end

    log_admin_activity('bulk_operation', {
      operation: 'bulk_promote',
      affected_users: promoted_count,
      role: role
    })

    redirect_to admin_users_path, notice: "#{promoted_count} users have been promoted to #{role}."
  end

  def bulk_demote
    user_ids = params[:user_ids] || []

    demoted_count = 0
    user_ids.each do |user_id|
      user = User.find(user_id)
      if user && user.can_access_admin? && user != current_user
        user.update!(role: 'user')
        demoted_count += 1
      end
    end

    log_admin_activity('bulk_operation', {
      operation: 'bulk_demote',
      affected_users: demoted_count
    })

    redirect_to admin_users_path, notice: "#{demoted_count} users have been demoted."
  end

  private

  def set_user
    @user = User.friendly.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:username, :full_name, :email, :bio, :job_title,
                                 :location, :admin_notes, :github_url, :linkedin_url,
                                 :website_url, :twitter_url, :contact_email, :phone)
  end

  def log_admin_activity(action, details = {})
    AdminActivity.create!(
      admin: current_user,
      action: action,
      target: @user,
      details: details,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
