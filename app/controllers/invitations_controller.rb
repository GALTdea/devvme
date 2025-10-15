class InvitationsController < ApplicationController
  before_action :find_user_by_token, only: [:show, :verify, :verify_access_code, :claim, :activate_account, :complete_profile, :update]
  before_action :validate_invitation, only: [:show, :verify, :verify_access_code, :claim, :activate_account, :complete_profile], unless: :account_already_active?
  before_action :require_verified_access, only: [:claim, :activate_account]
  before_action :require_signed_in, only: [:complete_profile, :update]

  # GET /invitations/:token/claim
  def show
    authorize @user, :show?, policy_class: InvitationPolicy

    # Show the invitation details and claim form
    @page_title = "Claim Your Profile - #{@user.display_name}"
    @invitation_data = build_invitation_data

    # If user is already signed in and it's their invitation, redirect to claim form
    if user_signed_in? && current_user == @user
      redirect_to claim_invitation_path(@user.invitation_token)
      return
    end

    # If user is signed in but it's not their invitation, show error
    if user_signed_in? && current_user != @user
      redirect_to root_path, alert: "You cannot claim another user's invitation."
      return
    end

    # Show invitation preview for anonymous users
    render :show
  end

  # GET /invitations/:token/verify
  def verify
    authorize @user, :claim?, policy_class: InvitationPolicy

    # Show the access code verification form
    @page_title = "Verify Your Identity - #{@user.display_name}"
    @invitation_data = build_invitation_data

    # If user is already signed in and it's their invitation
    if user_signed_in? && current_user == @user
      # Still require verification even if signed in
      render :verify
      return
    end

    # If user is signed in but it's not their invitation, show error
    if user_signed_in? && current_user != @user
      redirect_to root_path, alert: "You cannot claim another user's invitation."
      return
    end

    # For anonymous users, show verification form
    render :verify
  end

  # POST /invitations/:token/verify
  def verify_access_code
    authorize @user, :claim?, policy_class: InvitationPolicy

    access_code = params[:access_code]&.strip

    if @user.valid_access_code?(access_code)
      # Store verification in session
      session[:verified_invitation_token] = @user.invitation_token
      session[:verified_at] = Time.current.to_i

      # Redirect to claim form
      redirect_to claim_invitation_path(@user.invitation_token), notice: "Access code verified! You can now complete your profile setup."
    else
      # Invalid access code
      @invitation_data = build_invitation_data
      flash.now[:alert] = "Invalid access code. Please check your invitation email for the correct 6-digit code."
      render :verify
    end
  end

  # GET /invitations/:token/claim
  def claim
    authorize @user, :claim?, policy_class: InvitationPolicy

    # Show the claim form
    @page_title = "Complete Your Profile - #{@user.display_name}"
    @invitation_data = build_invitation_data

    # If user is already signed in and it's their invitation, show claim form
    if user_signed_in? && current_user == @user
      render :claim
      return
    end

    # If user is signed in but it's not their invitation, show error
    if user_signed_in? && current_user != @user
      redirect_to root_path, alert: "You cannot claim another user's invitation."
      return
    end

    # For anonymous users, show sign-in form first
    render :claim
  end

  # POST /invitations/:token/activate_account
  def activate_account
    authorize @user, :update?, policy_class: InvitationPolicy

    # Process only the password setup (Step 1)
    password = params[:user][:password]
    password_confirmation = params[:user][:password_confirmation]

    # Validate password
    if password.blank?
      @invitation_data = build_invitation_data
      flash.now[:alert] = "Password is required."
      render :claim
      return
    end

    if password.length < 6
      @invitation_data = build_invitation_data
      flash.now[:alert] = "Password must be at least 6 characters long."
      render :claim
      return
    end

    if password != password_confirmation
      @invitation_data = build_invitation_data
      flash.now[:alert] = "Password confirmation doesn't match."
      render :claim
      return
    end

    # Update user with password only
    if @user.update(password: password, password_confirmation: password_confirmation)
      # Activate account
      if @user.claim_invitation!
        # Sign in the user
        sign_in(@user)

        # Redirect to profile completion page
        redirect_to complete_profile_invitation_path(@user.invitation_token), notice: "🎉 Account activated! Now let's complete your profile."
      else
        @invitation_data = build_invitation_data
        flash.now[:alert] = "There was an error activating your account. Please try again."
        render :claim
      end
    else
      @invitation_data = build_invitation_data
      flash.now[:alert] = "Please fix the errors below."
      render :claim
    end
  end

  # GET /invitations/:token/complete_profile
  def complete_profile
    # Show the profile completion form (Step 2)
    @page_title = "Complete Your Profile - #{@user.display_name}"
    @invitation_data = build_invitation_data

    render :complete_profile
  end

  # PATCH/PUT /invitations/:token/update_profile
  def update
    authorize @user, :update?, policy_class: InvitationPolicy

    # Update profile information
    if @user.update(profile_update_params)
      track_successful_claim('profile_completion')

      # Send welcome email
      begin
        UserWelcomeMailer.welcome_notification(@user).deliver_later
      rescue => e
        Rails.logger.error "Failed to send welcome email to #{@user.email}: #{e.message}"
      end

      redirect_to dashboard_path, notice: "🎉 Welcome to Devv.me! Your profile is now complete and ready to showcase your work."
    else
      @invitation_data = build_invitation_data
      flash.now[:alert] = "Please fix the errors below."
      render :complete_profile
    end
  end

  private

  def require_signed_in
    unless user_signed_in? && current_user == @user
      redirect_to claim_invitation_path(@user.invitation_token), alert: "Please activate your account first."
      return false
    end
    true
  end

  def account_already_active?
    @user && @user.active?
  end

  def require_verified_access
    # Check if access code has been verified in this session
    verified_token = session[:verified_invitation_token]
    verified_at = session[:verified_at]

    # Verification is valid for 30 minutes
    verification_expired = verified_at.nil? || Time.at(verified_at) < 30.minutes.ago

    # If not verified or verification expired, redirect to verification page
    if verified_token != @user.invitation_token || verification_expired
      # Clear expired verification
      session.delete(:verified_invitation_token)
      session.delete(:verified_at)

      redirect_to verify_invitation_path(@user.invitation_token),
                  alert: "Please verify your access code to continue."
      return false
    end

    true
  end

  def find_user_by_token
    @user = User.find_by(invitation_token: params[:token])

    unless @user
      redirect_to root_path, alert: "Invalid invitation link. Please check your email for the correct link."
      return false
    end

    true
  end

  def validate_invitation
    unless @user.invited?
      case @user.account_status
      when 'active'
        redirect_to root_path, notice: "This profile has already been claimed. You can sign in normally."
      when 'pending_activation'
        redirect_to root_path, alert: "This invitation is no longer valid."
      when 'suspended'
        redirect_to root_path, alert: "This account has been suspended."
      when 'deactivated'
        redirect_to root_path, alert: "This account has been deactivated."
      else
        redirect_to root_path, alert: "This invitation is no longer valid."
      end
      return false
    end

    if @user.invitation_expired?
      @expired = true
      @invitation_data = build_invitation_data # Set invitation data for expired view
      render :expired
      return false
    end

    true
  end

  def build_invitation_data
    {
      user: @user,
      expires_at: @user.invitation_sent_at + 30.days,
      days_remaining: ((@user.invitation_sent_at + 30.days).to_date - Date.current).to_i,
      expired: @user.invitation_expired?,
      profile_completion: @user.profile_completion_percentage,
      profile_url: "/#{@user.username}",
      admin_name: "Devv.me Team" # Could be enhanced to track who sent the invitation
    }
  end

  def profile_update_params
    params.require(:user).permit(
      :full_name, :bio, :headline, :job_title, :location, :phone,
      :github_url, :linkedin_url, :website_url, :twitter_url, :contact_email,
      :skills_list
    )
  end

  def track_successful_claim(claim_type)
    Rails.logger.info "Profile claimed successfully: #{@user.email} (#{claim_type})"

    # Could integrate with analytics services here
    # - Track conversion from invitation to active user
    # - Measure time from invitation to claim
    # - Track completion rates

    # For now, just log the event
    claim_data = {
      user_id: @user.id,
      email: @user.email,
      claim_type: claim_type,
      invitation_sent_at: @user.invitation_sent_at,
      claimed_at: Time.current,
      time_to_claim: Time.current - @user.invitation_sent_at,
      profile_completion_at_claim: @user.profile_completion_percentage
    }

    Rails.logger.info "Claim analytics: #{claim_data.to_json}"
  end
end
