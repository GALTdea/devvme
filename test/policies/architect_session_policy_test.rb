# frozen_string_literal: true

require "test_helper"

class ArchitectSessionPolicyTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "policy_user@example.com",
      password: "password123",
      username: "policyuser",
      full_name: "Policy User"
    )
    @user.update!(account_status: :active)
    @other = User.create!(
      email: "other_policy@example.com",
      password: "password123",
      username: "otherpolicy",
      full_name: "Other User"
    )
    @other.update!(account_status: :active)
    @session = ArchitectSession.create!(
      user: @user,
      goal: "both",
      status: :in_progress
    )
  end

  test "create? allows signed-in user" do
    policy = ArchitectSessionPolicy.new(@user, ArchitectSession.new)
    assert policy.create?
  end

  test "create? denies nil user" do
    policy = ArchitectSessionPolicy.new(nil, ArchitectSession.new)
    assert_not policy.create?
  end

  test "show? allows owner" do
    policy = ArchitectSessionPolicy.new(@user, @session)
    assert policy.show?
  end

  test "show? denies non-owner" do
    policy = ArchitectSessionPolicy.new(@other, @session)
    assert_not policy.show?
  end

  test "message? allows owner" do
    policy = ArchitectSessionPolicy.new(@user, @session)
    assert policy.message?
  end

  test "message? denies non-owner" do
    policy = ArchitectSessionPolicy.new(@other, @session)
    assert_not policy.message?
  end

  test "accept? allows owner" do
    policy = ArchitectSessionPolicy.new(@user, @session)
    assert policy.accept?
  end

  test "accept? denies non-owner" do
    policy = ArchitectSessionPolicy.new(@other, @session)
    assert_not policy.accept?
  end

  test "destroy? allows owner" do
    policy = ArchitectSessionPolicy.new(@user, @session)
    assert policy.destroy?
  end

  test "destroy? denies non-owner" do
    policy = ArchitectSessionPolicy.new(@other, @session)
    assert_not policy.destroy?
  end

  test "scope resolves to user sessions only" do
    other_session = ArchitectSession.create!(user: @other, goal: "bio", status: :in_progress)
    scope = ArchitectSessionPolicy::Scope.new(@user, ArchitectSession.all).resolve
    assert_includes scope, @session
    assert_not_includes scope, other_session
  end

  test "scope returns none for nil user" do
    scope = ArchitectSessionPolicy::Scope.new(nil, ArchitectSession.all).resolve
    assert_empty scope.to_a
  end
end
