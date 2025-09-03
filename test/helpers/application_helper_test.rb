require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @admin_user = User.create!(
      email: "admin@example.com",
      password: "password123",
      username: "admin",
      role: :admin,
      account_status: :active
    )
    
    @project = @user.projects.create!(
      title: "Test Project",
      description: "A test project",
      status: :published,
      technologies_used: ["Ruby", "Rails"],
      display_order: 1
    )
  end

  # Project Permission Helper Tests
  test "can_edit_project? returns true for project owner" do
    # Mock current_user
    def current_user
      @user
    end
    
    def user_signed_in?
      true
    end
    
    assert can_edit_project?(@project)
  end

  test "can_edit_project? returns true for admin" do
    # Mock current_user
    def current_user
      @admin_user
    end
    
    def user_signed_in?
      true
    end
    
    assert can_edit_project?(@project)
  end

  test "can_edit_project? returns false for other users" do
    # Mock current_user
    def current_user
      @other_user
    end
    
    def user_signed_in?
      true
    end
    
    assert_not can_edit_project?(@project)
  end

  test "can_edit_project? returns false when not signed in" do
    # Mock user_signed_in?
    def user_signed_in?
      false
    end
    
    assert_not can_edit_project?(@project)
  end

  test "can_delete_project? returns true for project owner" do
    # Mock current_user
    def current_user
      @user
    end
    
    def user_signed_in?
      true
    end
    
    assert can_delete_project?(@project)
  end

  test "can_delete_project? returns true for admin" do
    # Mock current_user
    def current_user
      @admin_user
    end
    
    def user_signed_in?
      true
    end
    
    assert can_delete_project?(@project)
  end

  test "can_delete_project? returns false for other users" do
    # Mock current_user
    def current_user
      @other_user
    end
    
    def user_signed_in?
      true
    end
    
    assert_not can_delete_project?(@project)
  end

  test "can_view_project? returns true for published projects" do
    @project.update!(status: :published)
    
    # Mock user_signed_in?
    def user_signed_in?
      false
    end
    
    assert can_view_project?(@project)
  end

  test "can_view_project? returns false for draft projects when not signed in" do
    @project.update!(status: :draft)
    
    # Mock user_signed_in?
    def user_signed_in?
      false
    end
    
    assert_not can_view_project?(@project)
  end

  test "can_view_project? returns true for draft projects when owner" do
    @project.update!(status: :draft)
    
    # Mock current_user
    def current_user
      @user
    end
    
    def user_signed_in?
      true
    end
    
    assert can_view_project?(@project)
  end

  test "can_view_project? returns true for draft projects when admin" do
    @project.update!(status: :draft)
    
    # Mock current_user
    def current_user
      @admin_user
    end
    
    def user_signed_in?
      true
    end
    
    assert can_view_project?(@project)
  end

  test "can_manage_project? is alias for can_edit_project?" do
    # Mock current_user
    def current_user
      @user
    end
    
    def user_signed_in?
      true
    end
    
    assert_equal can_edit_project?(@project), can_manage_project?(@project)
  end

  # Admin Permission Helper Tests
  test "is_admin? returns true for admin user" do
    # Mock current_user
    def current_user
      @admin_user
    end
    
    def user_signed_in?
      true
    end
    
    assert is_admin?
  end

  test "is_admin? returns true for super admin user" do
    super_admin = User.create!(
      email: "superadmin@example.com",
      password: "password123",
      username: "superadmin",
      role: :super_admin,
      account_status: :active
    )
    
    # Mock current_user
    def current_user
      super_admin
    end
    
    def user_signed_in?
      true
    end
    
    assert is_admin?
  end

  test "is_admin? returns false for regular user" do
    # Mock current_user
    def current_user
      @user
    end
    
    def user_signed_in?
      true
    end
    
    assert_not is_admin?
  end

  test "is_admin? returns false when not signed in" do
    # Mock user_signed_in?
    def user_signed_in?
      false
    end
    
    assert_not is_admin?
  end

  test "is_super_admin? returns true for super admin user" do
    super_admin = User.create!(
      email: "superadmin@example.com",
      password: "password123",
      username: "superadmin",
      role: :super_admin,
      account_status: :active
    )
    
    # Mock current_user
    def current_user
      super_admin
    end
    
    def user_signed_in?
      true
    end
    
    assert is_super_admin?
  end

  test "is_super_admin? returns false for regular admin" do
    # Mock current_user
    def current_user
      @admin_user
    end
    
    def user_signed_in?
      true
    end
    
    assert_not is_super_admin?
  end

  test "is_super_admin? returns false for regular user" do
    # Mock current_user
    def current_user
      @user
    end
    
    def user_signed_in?
      true
    end
    
    assert_not is_super_admin?
  end

  test "can_manage_users? returns true for admin" do
    # Mock current_user
    def current_user
      @admin_user
    end
    
    def user_signed_in?
      true
    end
    
    assert can_manage_users?
  end

  test "can_manage_users? returns true for super admin" do
    super_admin = User.create!(
      email: "superadmin@example.com",
      password: "password123",
      username: "superadmin",
      role: :super_admin,
      account_status: :active
    )
    
    # Mock current_user
    def current_user
      super_admin
    end
    
    def user_signed_in?
      true
    end
    
    assert can_manage_users?
  end

  test "can_manage_users? returns false for regular user" do
    # Mock current_user
    def current_user
      @user
    end
    
    def user_signed_in?
      true
    end
    
    assert_not can_manage_users?
  end

  test "can_manage_users? returns false when not signed in" do
    # Mock user_signed_in?
    def user_signed_in?
      false
    end
    
    assert_not can_manage_users?
  end

  # Edge Cases
  test "permission helpers handle nil project gracefully" do
    # Mock current_user
    def current_user
      @user
    end
    
    def user_signed_in?
      true
    end
    
    # Should not crash with nil project
    assert_not can_edit_project?(nil)
    assert_not can_delete_project?(nil)
    assert_not can_view_project?(nil)
    assert_not can_manage_project?(nil)
  end

  test "permission helpers handle nil current_user gracefully" do
    # Mock current_user
    def current_user
      nil
    end
    
    def user_signed_in?
      false
    end
    
    # Should not crash with nil current_user
    assert_not can_edit_project?(@project)
    assert_not can_delete_project?(@project)
    assert_not can_view_project?(@project)
    assert_not can_manage_project?(@project)
    assert_not is_admin?
    assert_not is_super_admin?
    assert_not can_manage_users?
  end

  # Integration with User Model
  test "permission helpers work with user model methods" do
    # Mock current_user
    def current_user
      @admin_user
    end
    
    def user_signed_in?
      true
    end
    
    # Test that helper methods work with user model methods
    assert @admin_user.can_access_admin?
    assert is_admin?
    assert can_edit_project?(@project)
  end

  test "permission helpers respect user account status" do
    # Create suspended admin
    suspended_admin = User.create!(
      email: "suspended@example.com",
      password: "password123",
      username: "suspended",
      role: :admin,
      account_status: :suspended
    )
    
    # Mock current_user
    def current_user
      suspended_admin
    end
    
    def user_signed_in?
      true
    end
    
    # Suspended admin should still have admin permissions
    # (account status is separate from role permissions)
    assert is_admin?
    assert can_edit_project?(@project)
  end
end
