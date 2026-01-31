# frozen_string_literal: true

# == Schema Information
#
# Table name: architect_messages
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  content              :text             not null
#  insight_type         :string
#  metadata             :jsonb            not null
#  role                 :string           not null
#  sequence             :integer          not null
#  topic                :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  architect_session_id :bigint           not null
#
# Indexes
#
#  index_architect_messages_on_architect_session_id               (architect_session_id)
#  index_architect_messages_on_architect_session_id_and_sequence  (architect_session_id,sequence) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (architect_session_id => architect_sessions.id)
#
require "test_helper"

class ArchitectMessageTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "architect_msg_user@example.com",
      password: "password123",
      username: "archmsguser",
      full_name: "Architect Message User"
    )
    @user.update!(account_status: :active)
    @session = ArchitectSession.create!(
      user: @user,
      goal: "both",
      status: :in_progress
    )
    @message = ArchitectMessage.new(
      architect_session: @session,
      role: "assistant",
      content: "Hello, how can I help?",
      sequence: 0
    )
  end

  test "should be valid with valid attributes" do
    assert @message.valid?
  end

  test "should require content" do
    @message.content = nil
    assert_not @message.valid?
    assert_includes @message.errors[:content], "can't be blank"
  end

  test "should require sequence" do
    @message.sequence = nil
    assert_not @message.valid?
    assert_includes @message.errors[:sequence], "can't be blank"
  end

  test "should require sequence >= 0" do
    @message.sequence = -1
    assert_not @message.valid?
  end

  test "should require sequence uniqueness per session" do
    @message.save!
    duplicate = ArchitectMessage.new(
      architect_session: @session,
      role: :user,
      content: "Reply",
      sequence: 0
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:sequence], "has already been taken"
  end

  test "should allow same sequence in different sessions" do
    @message.save!
    other_session = ArchitectSession.create!(user: @user, goal: "bio", status: :in_progress)
    other_msg = ArchitectMessage.new(
      architect_session: other_session,
      role: :user,
      content: "Hi",
      sequence: 0
    )
    assert other_msg.valid?
  end

  test "should belong to architect_session" do
    assert_respond_to @message, :architect_session
    @message.save!
    assert_equal @session, @message.architect_session
  end

  test "role enum with prefix" do
    @message.role = "user"
    assert @message.message_user?
    @message.role = "assistant"
    assert @message.message_assistant?
  end

  test "scope ordered orders by sequence" do
    ArchitectMessage.create!(architect_session: @session, role: :assistant, content: "First", sequence: 0)
    ArchitectMessage.create!(architect_session: @session, role: :user, content: "Second", sequence: 1)
    ordered = @session.architect_messages.ordered.to_a
    assert_equal 0, ordered.first.sequence
    assert_equal 1, ordered.last.sequence
  end

  test "metadata returns hash" do
    assert_equal({}, @message.metadata)
    @message.metadata = { "key" => "value" }
    assert_equal({ "key" => "value" }, @message.metadata)
  end
end
