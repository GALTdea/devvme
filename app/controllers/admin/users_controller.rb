class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy, :suspend, :unsuspend, :activate, :deactivate, :promote, :demote, :resend_invitation, :generate_invitation_link, :toggle_featured]

  include Pagy::Backend

  def index
    authorize [:admin, User], :index?

    @pagy, @users = pagy(
      User.includes(:projects, :blog_posts)
          .order(params[:sort] || 'created_at DESC'),
      limit: 20
    )

    # Apply filters
    @users = @users.where(role: params[:role]) if params[:role].present?

    # Filter by account status
    case params[:status]
    when 'pending_activation'
      @users = @users.where(account_status: :pending_activation)
    when 'invited'
      @users = @users.where(account_status: :invited)
    when 'active'
      @users = @users.where(account_status: :active)
    when 'suspended'
      @users = @users.where(account_status: :suspended)
    when 'deactivated'
      @users = @users.where(account_status: :deactivated)
    end

    # Filter by featured status
    if params[:featured] == 'true'
      @users = @users.where(featured: true)
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where(
        "username ILIKE ? OR full_name ILIKE ? OR email ILIKE ?",
        search_term, search_term, search_term
      )
    end

    @total_users = User.count
    @active_users = User.where(account_status: :active).count
    @pending_activation_users = User.where(account_status: :pending_activation).count
    @invited_users = User.where(account_status: :invited).count
    @suspended_users = User.where(account_status: :suspended).count
    @deactivated_users = User.where(account_status: :deactivated).count
    @admin_users = User.where(role: [:admin, :super_admin]).count
    @featured_users_count = User.where(featured: true).count
  end

  def show
    authorize [:admin, @user], :show?

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

  def new
    authorize [:admin, User], :new?

    @user = User.new
    @user.role = 'user' # Default role
  end

  def create
    authorize [:admin, User], :create?

    @user = User.new(user_creation_params)
    @user.account_status = :invited
    send_email = params[:send_invitation_email] != '0'

    if @user.save
      # Generate invitation token and optionally send email
      @user.invite!(admin: current_user, send_email: send_email)

      log_admin_activity('create_invited_user', {
        username: @user.username,
        email: @user.email,
        role: @user.role,
        invitation_sent: send_email
      })

      if send_email
        redirect_to admin_user_path(@user), notice: "User '#{@user.username}' has been created and invitation sent to #{@user.email}."
      else
        # Store invitation link in flash for display
        invitation_url = "#{request.base_url}/invitations/#{@user.invitation_token}/claim"
        flash[:invitation_link] = invitation_url
        redirect_to admin_user_path(@user), notice: "User '#{@user.username}' has been created. Invitation link generated (no email sent)."
      end
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Failed to create invited user: #{e.message}"
    @user.errors.add(:base, "Failed to create user: #{e.message}")
    render :new, status: :unprocessable_entity
  end

  def destroy
    authorize [:admin, @user], :destroy?
    # Rails.logger.info "Destroying user: #{@user.username}"
    puts "This is the policy: #{policy(@user).class}##{action_name}?"
    Rails.logger.info "POLICY: #{policy(@user).class}##{action_name}?"

    username = @user.username
    @user.destroy!
    log_admin_activity('delete_user', { username: username })
    redirect_to admin_users_path, notice: "User '#{username}' has been deleted."
  end

  def suspend
    authorize [:admin, @user], :suspend?

    reason = params[:suspension_reason] || 'Suspended by admin'
    @user.suspend!(reason: reason, admin: current_user)
    redirect_to admin_user_path(@user), notice: 'User has been suspended.'
  end

  def unsuspend
    authorize [:admin, @user], :unsuspend?

    @user.unsuspend!(admin: current_user)
    redirect_to admin_user_path(@user), notice: 'User has been unsuspended.'
  end

  def activate
    authorize [:admin, @user], :activate?

    @user.activate_account!(admin: current_user)
    redirect_to admin_user_path(@user), notice: 'User account has been activated.'
  end

  def deactivate
    authorize [:admin, @user], :deactivate?

    reason = params[:reason] || 'Account deactivated by admin'
    @user.deactivate_account!(reason: reason, admin: current_user)
    redirect_to admin_user_path(@user), notice: 'User account has been deactivated.'
  end

  def promote
    authorize [:admin, @user], :promote?

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
    authorize [:admin, @user], :demote?

    old_role = @user.role
    @user.update!(role: 'user')
    log_admin_activity('demote_user', {
      old_role: old_role,
      new_role: @user.role,
      target_username: @user.username
    })
    redirect_to admin_user_path(@user), notice: 'User demoted to regular user.'
  end

  def resend_invitation
    authorize [:admin, @user], :resend_invitation?

    if @user.invited? && @user.invitation_pending?
      @user.invite!(admin: current_user, send_email: true)
      log_admin_activity('resend_invitation', {
        username: @user.username,
        email: @user.email
      })
      redirect_to admin_user_path(@user), notice: 'Invitation has been resent.'
    elsif @user.invited? && @user.invitation_expired?
      # Generate new token for expired invitations
      @user.invite!(admin: current_user, send_email: true)
      log_admin_activity('resend_expired_invitation', {
        username: @user.username,
        email: @user.email
      })
      redirect_to admin_user_path(@user), notice: 'New invitation has been sent (previous invitation expired).'
    else
      redirect_to admin_user_path(@user), alert: 'Cannot resend invitation for this user.'
    end
  end

  def generate_invitation_link
    authorize [:admin, @user], :resend_invitation?

    if @user.invited?
      # Generate new token if expired or refresh existing one
      if @user.invitation_expired? || @user.invitation_token.blank?
        @user.invite!(admin: current_user, send_email: false)
        log_admin_activity('generate_new_invitation_link', {
          username: @user.username,
          email: @user.email
        })
      end

      invitation_url = "#{request.base_url}/invitations/#{@user.invitation_token}/claim"
      flash[:invitation_link] = invitation_url
      redirect_to admin_user_path(@user), notice: 'Invitation link generated successfully (no email sent).'
    else
      redirect_to admin_user_path(@user), alert: 'Cannot generate invitation link for this user.'
    end
  end

  def toggle_featured
    authorize [:admin, @user], :update?

    @user.toggle_featured!(admin: current_user)
    status = @user.featured? ? 'featured' : 'unfeatured'

    # Redirect back to index if coming from there, preserving filters
    if params[:from_index].present?
      redirect_to admin_users_path(
        search: params[:search],
        role: params[:role],
        status: params[:status],
        featured: params[:featured]
      ), notice: "#{@user.display_name} has been #{status} successfully."
    else
      redirect_to admin_user_path(@user), notice: "User has been #{status} successfully."
    end
  end

  def bulk_suspend
    authorize [:admin, User], :bulk_suspend?

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
    authorize [:admin, User], :bulk_delete?

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
    authorize [:admin, User], :bulk_promote?

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
    authorize [:admin, User], :bulk_demote?

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

  def user_creation_params
    params.require(:user).permit(:username, :full_name, :email, :bio, :job_title,
                                 :location, :admin_notes, :github_url, :linkedin_url,
                                 :website_url, :twitter_url, :contact_email, :phone,
                                 :headline, :role, skills: [])
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
