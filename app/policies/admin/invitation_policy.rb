class Admin::InvitationPolicy < ApplicationPolicy
  # Admin invitation management policy

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Basic invitation management access
  def index?
    user&.can_access_admin? || false
  end

  def show?
    user&.can_access_admin? || false
  end

  # Analytics access
  def analytics?
    user&.can_access_admin? || false
  end

  # Bulk operations - super admin only
  def bulk_create?
    user&.super_admin? || false
  end

  def bulk_resend?
    user&.can_manage_users? || false
  end

  def bulk_expire?
    user&.super_admin? || false
  end

  # Cleanup operations - super admin only
  def cleanup?
    user&.super_admin? || false
  end

  # Individual invitation actions
  def resend?
    user&.can_manage_users? || false
  end

  def expire?
    user&.can_manage_users? || false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.can_access_admin?
        scope.where(account_status: :invited)
      else
        scope.none
      end
    end
  end

  private

  attr_reader :user, :record
end
