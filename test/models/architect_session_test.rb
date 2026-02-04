# frozen_string_literal: true

# == Schema Information
#
# Table name: architect_sessions
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  context_snapshot   :jsonb
#  context_version    :integer          default(1), not null
#  generated_bio      :text
#  generated_headline :text
#  goal               :string           not null
#  mode               :string           default("profile_builder"), not null
#  question_count     :integer          default(0), not null
#  result_data        :jsonb            not null
#  status             :string           default("draft"), not null
#  target_data        :jsonb            not null
#  target_type        :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_architect_sessions_on_mode                    (mode)
#  index_architect_sessions_on_status                  (status)
#  index_architect_sessions_on_target_type             (target_type)
#  index_architect_sessions_on_user_id                 (user_id)
#  index_architect_sessions_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class ArchitectSessionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "architect_user@example.com",
      password: "password123",
      username: "architectuser",
      full_name: "Architect User"
    )
    @user.update!(account_status: :active)
    @session = ArchitectSession.new(
      user: @user,
      goal: "both",
      status: :in_progress,
      context_snapshot: {}
    )
  end

  test "should be valid with valid attributes" do
    assert @session.valid?
  end

  test "should require goal" do
    @session.goal = nil
    assert_not @session.valid?
    assert_includes @session.errors[:goal], "can't be blank"
  end

  test "should accept valid goals" do
    %w[bio headline both].each do |goal|
      @session.goal = goal
      assert @session.valid?, "goal #{goal} should be valid"
    end
  end

  test "should accept valid modes" do
    ArchitectSession::MODES.each do |mode|
      @session.mode = mode
      assert @session.valid?, "mode #{mode} should be valid"
    end
  end

  test "should reject invalid mode" do
    assert_raises(ArgumentError) do
      @session.mode = "something_else"
    end
  end

  test "should accept valid target_type or nil" do
    @session.target_type = nil
    assert @session.valid?

    ArchitectSession::TARGET_TYPES.each do |target_type|
      @session.target_type = target_type
      assert @session.valid?, "target_type #{target_type} should be valid"
    end
  end

  test "should reject invalid target_type" do
    @session.target_type = "random"
    assert_not @session.valid?
    assert_includes @session.errors[:target_type], "is not included in the list"
  end

  test "should validate generated_bio length when present" do
    @session.generated_bio = "x" * 501
    assert_not @session.valid?
    assert_includes @session.errors[:generated_bio], "is too long (maximum is 500 characters)"
  end

  test "should allow blank generated_bio" do
    @session.generated_bio = ""
    assert @session.valid?
  end

  test "should validate generated_headline length when present" do
    @session.generated_headline = "x" * 201
    assert_not @session.valid?
    assert_includes @session.errors[:generated_headline], "is too long (maximum is 200 characters)"
  end

  test "should allow blank generated_headline" do
    @session.generated_headline = ""
    assert @session.valid?
  end

  test "should validate question_count is non-negative integer" do
    @session.question_count = -1
    assert_not @session.valid?
    @session.question_count = 0
    assert @session.valid?
    @session.question_count = 1.5
    assert_not @session.valid?
  end

  test "should belong to user" do
    assert_respond_to @session, :user
    @session.save!
    assert_equal @user, @session.user
  end

  test "should have many architect_messages" do
    assert_respond_to @session, :architect_messages
    @session.save!
    @session.architect_messages.create!(role: :user, content: "Hello", sequence: 0)
    assert_equal 1, @session.architect_messages.count
  end

  test "status enum" do
    @session.save!
    @session.draft!
    assert @session.draft?
    @session.in_progress!
    assert @session.in_progress?
    @session.completed!
    assert @session.completed?
    @session.abandoned!
    assert @session.abandoned?
  end

  test "goal enum with prefix" do
    @session.goal = "bio"
    assert @session.goal_bio?
    @session.goal = "headline"
    assert @session.goal_headline?
    @session.goal = "both"
    assert @session.goal_both?
  end

  test "context_snapshot returns hash" do
    assert_equal({}, @session.context_snapshot)
    @session.context_snapshot = { "user_profile" => {} }
    assert_equal({ "user_profile" => {} }, @session.context_snapshot)
  end

  test "target_data returns hash" do
    assert_equal({}, @session.target_data)
    @session.target_data = { "job_description_text" => "Rails role" }
    assert_equal({ "job_description_text" => "Rails role" }, @session.target_data)
  end

  test "result_data returns hash" do
    assert_equal({}, @session.result_data)
    @session.result_data = { "requirements" => [] }
    assert_equal({ "requirements" => [] }, @session.result_data)
  end

  test "scope recent orders by created_at desc" do
    @session.save!
    older = ArchitectSession.create!(user: @user, goal: "both", status: :in_progress, created_at: 1.hour.ago)
    recent = ArchitectSession.recent.to_a
    assert_equal @session.id, recent.first.id
    assert_equal older.id, recent.last.id
  end

  test "scope for_user filters by user" do
    @session.save!
    other = User.create!(email: "other@example.com", password: "password123", username: "otheruser")
    other.update!(account_status: :active)
    other_session = ArchitectSession.create!(user: other, goal: "both", status: :in_progress)
    scope = ArchitectSession.for_user(@user)
    assert_includes scope, @session
    assert_not_includes scope, other_session
  end
end
