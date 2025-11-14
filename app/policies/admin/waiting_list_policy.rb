class Admin::WaitingListPolicy < ApplicationPolicy
  # Admin waiting list management policy

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Basic waiting list management access
  def index?
    user&.can_access_admin? || false
  end

  def show?
    user&.can_access_admin? || false
  end

  # Approval actions - any admin can approve
  def approve?
    user&.can_manage_users? || false
  end

  def decline?
    user&.can_manage_users? || false
  end

  # Bulk operations - super admin only
  def bulk_approve?
    user&.super_admin? || false
  end

  def bulk_decline?
    user&.super_admin? || false
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

