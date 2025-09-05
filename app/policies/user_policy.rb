class UserPolicy < ApplicationPolicy
  # Basic activation status checks
  def can_access_application?
    user&.can_access_application? || false
  end

  def pending_activation?
    user&.pending_activation? || false
  end

  def active_user?
    user&.active? || false
  end

  # Dashboard access - only active users can access dashboard
  def can_access_dashboard?
    active_user? && !(user&.suspended? || false)
  end

  # Project management - only active users can create/manage projects
  def can_create_projects?
    active_user? && !(user&.suspended? || false)
  end

  def can_edit_projects?
    active_user? && !(user&.suspended? || false)
  end

  def can_destroy_projects?
    active_user? && !(user&.suspended? || false)
  end

  # Profile management - pending users can view their own profile, active users can edit
  def can_edit_profile?
    active_user? && !(user&.suspended? || false)
  end

  def can_view_profile?
    # Users can always view their own profile, even if pending activation
    user.present?
  end

  # Blog post management - only active users can create/manage blog posts
  def can_create_blog_posts?
    active_user? && !(user&.suspended? || false)
  end

  def can_edit_blog_posts?
    active_user? && !(user&.suspended? || false)
  end

  def can_destroy_blog_posts?
    active_user? && !(user&.suspended? || false)
  end

  # Admin access - existing admin methods
  def can_access_admin?
    user&.can_access_admin?
  end

  def can_manage_users?
    user&.can_manage_users?
  end

  # Standard Pundit methods
  def index?
    can_access_application?
  end

  def show?
    can_view_profile?
  end

  def create?
    can_create_projects?
  end

  def update?
    can_edit_profile?
  end

  def destroy?
    can_manage_users?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Only show users that the current user can access
      if user&.can_access_admin?
        scope.all
      else
        # Regular users can only see public profiles
        scope.where(account_status: :active)
      end
    end
  end
end
