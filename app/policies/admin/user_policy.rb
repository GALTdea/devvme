class Admin::UserPolicy < ApplicationPolicy
  # Admin-specific user management policy

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Basic admin access to user management
  def index?
    user&.can_access_admin? || false
  end

  def show?
    user&.can_access_admin? || false
  end

  # User creation - only super admins
  def new?
    user&.super_admin? || false
  end

  def create?
    user&.super_admin? || false
  end

  # User editing - admins can edit basic info, super admins can edit all
  def edit?
    user&.can_manage_users? || false
  end

  def update?
    user&.can_manage_users? || false
  end

  # User deletion - only super admins
  def destroy?
    user&.super_admin? || false
  end

  # Account status management
  def activate?
    user&.can_manage_users? || false
  end

  def deactivate?
    user&.can_manage_users? || false
  end

  def suspend?
    user&.can_manage_users? || false
  end

  def unsuspend?
    user&.can_manage_users? || false
  end

  # Role management - only super admins
  def promote?
    user&.super_admin? || false
  end

  def demote?
    user&.super_admin? || false
  end

  # Invitation management
  def resend_invitation?
    user&.can_manage_users? || false
  end

  # Bulk operations - only super admins
  def bulk_suspend?
    user&.super_admin? || false
  end

  def bulk_delete?
    user&.super_admin? || false
  end

  def bulk_promote?
    user&.super_admin? || false
  end

  def bulk_demote?
    user&.super_admin? || false
  end

  # Prevent self-targeting for destructive actions
  def can_target_user?
    return false if record == user # Can't target self
    return false if record&.super_admin? && !user&.super_admin? # Regular admins can't target super admins
    true
  end

  # Override methods to include self-targeting checks
  def destroy?
    super && can_target_user?
  end

  def suspend?
    super && can_target_user?
  end

  def demote?
    super && can_target_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.can_access_admin?
        scope.all
      else
        scope.none
      end
    end
  end

  private

  attr_reader :user, :record
end
