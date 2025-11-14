require "test_helper"

class WaitingListEntryTest < ActiveSupport::TestCase
  def setup
    @entry = WaitingListEntry.new(
      email: "test@example.com",
      full_name: "Test User",
      source: "direct"
    )
  end

  # Validation tests
  test "should be valid with valid attributes" do
    assert @entry.valid?
  end

  test "should require email" do
    @entry.email = nil
    assert_not @entry.valid?
    assert_includes @entry.errors[:email], "can't be blank"
  end

  test "should require valid email format" do
    @entry.email = "invalid-email"
    assert_not @entry.valid?
    assert_includes @entry.errors[:email], "is invalid"
  end

  test "should prevent duplicate pending emails" do
    @entry.save!
    duplicate = WaitingListEntry.new(email: "test@example.com")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "is already on the waiting list"
  end

  test "should allow same email if previous entry is converted" do
    @entry.save!
    @entry.update!(status: :converted)

    new_entry = WaitingListEntry.new(email: "test@example.com")
    assert new_entry.valid?
  end

  test "should auto-assign position before create" do
    # Clear any existing entries to ensure clean test
    WaitingListEntry.delete_all

    entry1 = WaitingListEntry.create!(email: "test1@example.com")
    entry2 = WaitingListEntry.create!(email: "test2@example.com")

    assert_equal 1, entry1.position
    assert_equal 2, entry2.position
  end

  # Enum tests
  test "should default to pending status" do
    entry = WaitingListEntry.create!(email: "test@example.com")
    assert entry.pending?
  end

  test "should transition through statuses" do
    @entry.save!
    assert @entry.pending?

    @entry.update!(status: :invited)
    assert @entry.invited?

    @entry.update!(status: :converted)
    assert @entry.converted?
  end

  # Scope tests
  test "pending scope should return only pending entries" do
    pending = WaitingListEntry.create!(email: "pending@example.com", status: :pending)
    invited = WaitingListEntry.create!(email: "invited@example.com", status: :invited)

    pending_entries = WaitingListEntry.pending
    assert_includes pending_entries, pending
    assert_not_includes pending_entries, invited
  end

  # Approve and invite tests
  test "approve_and_invite! should create user and update entry" do
    @entry.save!
    admin = users(:test_admin)

    user = @entry.approve_and_invite!(admin: admin)

    assert user.persisted?
    assert_equal @entry.email, user.email
    assert user.invited?
    assert @entry.reload.invited?
    assert_not_nil @entry.user_id
    assert_not_nil @entry.notified_at
  end

  test "mark_as_converted! should update status and timestamp" do
    @entry.save!
    @entry.mark_as_converted!

    assert @entry.converted?
    assert_not_nil @entry.converted_at
  end

  test "mark_as_declined! should update status" do
    @entry.save!
    @entry.mark_as_declined!

    assert @entry.declined?
  end

  # Username generation tests
  test "should generate username from full name" do
    @entry.full_name = "John Doe"
    @entry.save!

    admin = users(:test_admin)
    user = @entry.approve_and_invite!(admin: admin)

    assert_match /john_doe/, user.username
  end

  test "should generate unique usernames" do
    # Create an existing user
    User.create!(
      email: "existing@example.com",
      username: "testuser",
      password: "password123",
      account_status: :active
    )

    entry = WaitingListEntry.create!(
      email: "test@example.com",
      full_name: "TestUser" # This would normally generate "testuser"
    )

    admin = users(:test_admin)
    user = entry.approve_and_invite!(admin: admin)

    # Should generate testuser1 or similar
    assert_not_equal "testuser", user.username
  end
end
