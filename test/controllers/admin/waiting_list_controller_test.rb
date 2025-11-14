require "test_helper"

class Admin::WaitingListControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:test_admin)
    sign_in @admin

    @pending_entry = WaitingListEntry.create!(
      email: "pending@example.com",
      full_name: "Pending User",
      status: :pending
    )

    @invited_entry = WaitingListEntry.create!(
      email: "invited@example.com",
      full_name: "Invited User",
      status: :invited
    )
  end

  test "should require authentication" do
    sign_out @admin
    get admin_waiting_list_index_path
    assert_redirected_to new_user_session_path
  end

  test "should require admin privileges" do
    sign_out @admin
    regular_user = users(:test_user_one)
    sign_in regular_user

    get admin_waiting_list_index_path
    assert_redirected_to root_path
  end

  test "should get index" do
    get admin_waiting_list_index_path
    assert_response :success
    assert_select "h1", text: /Waiting List Management/i
  end

  test "should display statistics on index" do
    get admin_waiting_list_index_path
    assert_response :success

    # Check for stats display
    assert_select ".text-sm", text: /Total Signups/i
    assert_select ".text-sm", text: /Pending/i
    assert_select ".text-sm", text: /Invited/i
  end

  test "should filter by status" do
    get admin_waiting_list_index_path, params: { status: 'pending' }
    assert_response :success
    # The response should contain pending entries
  end

  test "should search by email" do
    get admin_waiting_list_index_path, params: { search: 'pending@example.com' }
    assert_response :success
    # The response should contain the searched entry
  end

  test "should show waiting list entry" do
    get admin_waiting_list_path(@pending_entry)
    assert_response :success
    assert_select "dd", text: @pending_entry.email
  end

  test "should approve and invite pending entry" do
    assert_difference('User.count', 1) do
      patch approve_admin_waiting_list_path(@pending_entry)
    end

    assert_redirected_to admin_waiting_list_index_path
    assert_equal "Successfully approved and invited #{@pending_entry.email}. Invitation email has been sent.", flash[:notice]

    @pending_entry.reload
    assert @pending_entry.invited?
    assert_not_nil @pending_entry.user_id
    assert_not_nil @pending_entry.notified_at
  end

  test "should not approve already invited entry" do
    # Test approving an already invited entry
    original_user_count = User.count
    patch approve_admin_waiting_list_path(@invited_entry)

    # Should not create a new user
    assert_equal original_user_count, User.count
  end

  test "should decline pending entry" do
    patch decline_admin_waiting_list_path(@pending_entry)

    assert_redirected_to admin_waiting_list_index_path
    assert_equal "Declined waiting list entry for #{@pending_entry.email}.", flash[:notice]

    @pending_entry.reload
    assert @pending_entry.declined?
  end

  test "should log admin activities" do
    assert_difference('AdminActivity.count', 2) do # view + approve
      patch approve_admin_waiting_list_path(@pending_entry)
    end

    activity = AdminActivity.last
    assert_equal @admin, activity.admin
    assert_equal 'approve_waiting_list_entry', activity.action
    assert_equal @pending_entry.email, activity.details['email']
  end
end
