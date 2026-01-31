# frozen_string_literal: true

require "test_helper"

class ArchitectFlowTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "arch_flow@example.com",
      password: "password123",
      username: "archflow",
      full_name: "Architect Flow User"
    )
    @user.update!(account_status: :active, allow_career_architect: true)
  end

  test "signed-in user can reach new architect session" do
    sign_in @user
    get new_architect_session_path
    assert_response :success
    assert_select "h1", text: /Career Architect/
    assert_select "form[action='#{architect_sessions_path}']"
  end

  test "signed-in user can create session and is redirected to show" do
    sign_in @user
    created_session = ArchitectSession.create!(user: @user, goal: "both", status: :in_progress)
    original = ArchitectService.method(:start_session)
    ArchitectService.define_singleton_method(:start_session) { |*_args, **_opts| { session: created_session } }
    post architect_sessions_path, params: { architect_session: { goal: "both" } }
    assert_redirected_to architect_session_path(created_session)
    follow_redirect!
    assert_response :success
    assert_select "h1", text: /Career Architect/
  ensure
    ArchitectService.define_singleton_method(:start_session) { |*args, **opts| original.call(*args, **opts) }
  end

  test "signed-in user can view session show and send message" do
    session = ArchitectSession.create!(user: @user, goal: "both", status: :in_progress)
    session.architect_messages.create!(role: :assistant, content: "What do you do?", sequence: 0)
    sign_in @user
    get architect_session_path(session)
    assert_response :success
    assert_select "#architect_messages"
    assert_select "form[action='#{message_architect_session_path(session)}']"

    post message_architect_session_path(session), params: { architect_message: { content: "I build web apps." } }, as: :turbo_stream
    assert_response :success
    session.reload
    assert session.architect_messages.where(role: :user).exists?
  end

  test "signed-in user can accept and redirect when session completed" do
    session = ArchitectSession.create!(
      user: @user,
      goal: "both",
      status: :completed,
      generated_bio: "A developer.",
      generated_headline: "Developer"
    )
    sign_in @user
    patch accept_architect_session_path(session)
    assert_redirected_to profile_path
    @user.reload
    assert_equal "A developer.", @user.bio
    assert_equal "Developer", @user.headline
  end

  test "signed-in user can destroy session" do
    session = ArchitectSession.create!(user: @user, goal: "both", status: :in_progress)
    sign_in @user
    delete architect_session_path(session)
    assert_redirected_to dashboard_path
    assert_not ArchitectSession.exists?(session.id)
  end

  test "guest cannot access architect new" do
    get new_architect_session_path
    assert_redirected_to new_user_session_path
  end

  test "guest cannot access architect show" do
    session = ArchitectSession.create!(user: @user, goal: "both", status: :in_progress)
    get architect_session_path(session)
    assert_redirected_to new_user_session_path
  end
end
