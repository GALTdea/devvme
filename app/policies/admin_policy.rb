class AdminPolicy < ApplicationPolicy
  # Admin access control policy for admin namespace actions

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Basic admin access - requires admin or super_admin role
  def access_admin?
    user&.can_access_admin? || false
  end

  # User management permissions
  def manage_users?
    user&.can_manage_users? || false
  end

  # User creation permissions - only super admins can create users
  def create_users?
    user&.super_admin? || false
  end

  # User editing permissions - admins can edit, super admins can edit all
  def edit_users?
    user&.can_manage_users? || false
  end

  # User deletion permissions - only super admins
  def delete_users?
    user&.super_admin? || false
  end

  # Role management permissions - only super admins can promote/demote
  def manage_roles?
    user&.super_admin? || false
  end

  # Invitation management - admins can resend, super admins can create
  def manage_invitations?
    user&.can_manage_users? || false
  end

  def create_invitations?
    user&.super_admin? || false
  end

  def resend_invitations?
    user&.can_manage_users? || false
  end

  # Bulk operations - only super admins
  def bulk_operations?
    user&.super_admin? || false
  end

  # Content moderation permissions
  def moderate_content?
    user&.can_access_admin? || false
  end

  # Analytics access
  def view_analytics?
    user&.can_access_admin? || false
  end

  # Activity logs access
  def view_activities?
    user&.can_access_admin? || false
  end

  # Standard Pundit methods for admin namespace
  def index?
    access_admin?
  end

  def show?
    access_admin?
  end

  def new?
    create_users?
  end

  def create?
    create_users?
  end

  def edit?
    edit_users?
  end

  def update?
    edit_users?
  end

  def destroy?
    delete_users?
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
