class InvitationsController < ApplicationController
  before_action :find_user_by_token, only: [:show, :claim, :update]
  before_action :validate_invitation, only: [:show, :claim, :update]

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

  # PATCH/PUT /invitations/:token/claim
  def update
    authorize @user, :update?, policy_class: InvitationPolicy

    # Process the claim form submission
    @invitation_data = build_invitation_data

    # Handle different claim scenarios
    if user_signed_in? && current_user == @user
      # User is already signed in, just update profile and activate
      handle_profile_completion
    elsif params[:sign_in_existing].present?
      # User wants to sign in to existing account
      handle_existing_user_signin
    else
      # User is claiming for the first time, set password and activate
      handle_new_user_claim
    end
  end

  private

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

  def handle_profile_completion
    # User is already signed in, just update any profile changes and activate
    if @user.update(profile_update_params)
      if @user.claim_invitation!
        track_successful_claim('profile_completion')
        redirect_to dashboard_path, notice: "🎉 Welcome to Devv.me! Your profile is now active and ready to showcase your work."
      else
        flash.now[:alert] = "There was an error activating your profile. Please try again."
        render :claim
      end
    else
      flash.now[:alert] = "Please fix the errors below."
      render :claim
    end
  end

  def handle_existing_user_signin
    # User wants to sign in to an existing account
    email = params[:user][:email]
    password = params[:user][:password]

    # Find user by email
    existing_user = User.find_by(email: email)

    if existing_user && existing_user.valid_password?(password)
      # Check if this is the same user as the invitation
      if existing_user == @user
        # Same user, sign them in and proceed with claim
        sign_in(existing_user)
        handle_profile_completion
      else
        # Different user - this shouldn't happen normally
        flash.now[:alert] = "This invitation is for a different email address."
        render :claim
      end
    else
      flash.now[:alert] = "Invalid email or password."
      render :claim
    end
  end

  def handle_new_user_claim
    # User is claiming for the first time, set password and activate
    password = params[:user][:password]
    password_confirmation = params[:user][:password_confirmation]

    # Validate password
    if password.blank?
      flash.now[:alert] = "Password is required."
      render :claim
      return
    end

    if password.length < 6
      flash.now[:alert] = "Password must be at least 6 characters long."
      render :claim
      return
    end

    if password != password_confirmation
      flash.now[:alert] = "Password confirmation doesn't match."
      render :claim
      return
    end

    # Update user with password and profile changes
    user_params = profile_update_params.merge(
      password: password,
      password_confirmation: password_confirmation
    )

    if @user.update(user_params)
      if @user.claim_invitation!
        # Sign in the user
        sign_in(@user)
        track_successful_claim('new_user_claim')

        # Send welcome email
        begin
          UserWelcomeMailer.welcome_notification(@user).deliver_later
        rescue => e
          Rails.logger.error "Failed to send welcome email to #{@user.email}: #{e.message}"
        end

        redirect_to dashboard_path, notice: "🎉 Welcome to Devv.me! Your profile is now active. Check your email for next steps."
      else
        flash.now[:alert] = "There was an error activating your profile. Please try again."
        render :claim
      end
    else
      flash.now[:alert] = "Please fix the errors below."
      render :claim
    end
  end

  def profile_update_params
    params.require(:user).permit(
      :full_name, :bio, :headline, :job_title, :location, :phone,
      :github_url, :linkedin_url, :website_url, :twitter_url, :contact_email,
      skills: []
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
