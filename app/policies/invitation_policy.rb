class InvitationPolicy < ApplicationPolicy
  # Policy for public invitation claiming process

  def initialize(user, record)
    @user = user
    @record = record # This will be the User record with invitation
  end

  # Public access to view invitation details
  def show?
    return false unless record&.invited?
    return false if record&.invitation_expired?
    true
  end

  # Public access to claim invitation form
  def claim?
    return false unless record&.invited?
    return false if record&.invitation_expired?

    # If user is signed in, they can only claim their own invitation
    if user.present?
      return record.email == user.email
    end

    # Anonymous users can access claim form
    true
  end

  # Process invitation claim
  def update?
    return false unless record&.invited?
    return false if record&.invitation_expired?

    # If user is signed in, they can only claim their own invitation
    if user.present?
      return record.email == user.email
    end

    # Anonymous users can process claim
    true
  end

  # Helper methods for invitation status
  def valid_invitation?
    record&.invited? && !record&.invitation_expired?
  end

  def can_claim_invitation?
    return false unless valid_invitation?

    # Check if user is trying to claim someone else's invitation
    if user.present? && record.email != user.email
      return false
    end

    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Only return invitations that are valid and not expired
      scope.where(account_status: :invited)
           .where("invitation_sent_at > ?", 30.days.ago)
    end
  end

  private

  attr_reader :user, :record
end
