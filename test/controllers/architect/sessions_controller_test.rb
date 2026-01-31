# frozen_string_literal: true

require "test_helper"

module Architect
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @user = User.create!(
        email: "arch_ctrl@example.com",
        password: "password123",
        username: "archctrl",
        full_name: "Architect Controller User"
      )
      @user.update!(account_status: :active, allow_career_architect: true)
      @session = ArchitectSession.create!(
        user: @user,
        goal: "both",
        status: :in_progress
      )
    end

    test "should get new when signed in" do
      sign_in_user @user
      get new_architect_session_path
      assert_response :success
    end

    test "should redirect new when not signed in" do
      get new_architect_session_path
      assert_redirected_to new_user_session_path
    end

    test "should create session when signed in and under rate limit" do
      sign_in_user @user
      stub_architect_start_session({ session: @session }) do
        post architect_sessions_path, params: { architect_session: { goal: "both" } }
      end
      assert_redirected_to architect_session_path(@session)
      assert_equal I18n.t("architect.sessions.created"), flash[:notice]
    end

    test "should redirect to dashboard with alert when create raises MissingApiKeysError" do
      sign_in_user @user
      stub_architect_start_session(->(*) { raise ArchitectService::MissingApiKeysError, "no key" }) do
        post architect_sessions_path, params: { architect_session: { goal: "both" } }
      end
      assert_redirected_to dashboard_path
      assert_equal I18n.t("architect.errors.missing_api_keys"), flash[:alert]
    end

    test "should enforce create rate limit" do
      sign_in_user @user
      3.times { ArchitectSession.create!(user: @user, goal: "both", status: :in_progress, created_at: Time.current) }
      post architect_sessions_path, params: { architect_session: { goal: "both" } }
      assert_redirected_to dashboard_path
      assert_equal I18n.t("architect.errors.rate_limit_sessions"), flash[:alert]
    end

    test "should show session when owner" do
      sign_in_user @user
      get architect_session_path(@session)
      assert_response :success
    end

    test "should redirect show when not signed in" do
      get architect_session_path(@session)
      assert_redirected_to new_user_session_path
    end

    test "should redirect to dashboard when user does not have beta access" do
      @user.update!(allow_career_architect: false)
      sign_in_user @user
      get new_architect_session_path
      assert_redirected_to dashboard_path
      assert_equal I18n.t("architect.errors.beta_only"), flash[:alert]
    end

    test "should not show other user session" do
      other = User.create!(email: "other_ctrl@example.com", password: "password123", username: "otherctrl")
      other.update!(account_status: :active, allow_career_architect: true)
      sign_in_user other
      get architect_session_path(@session)
      assert_response :not_found
    end

    test "should post message when signed in and under message limit" do
      sign_in_user @user
      assert_difference("@session.architect_messages.count", 1) do
        post message_architect_session_path(@session), params: { architect_message: { content: "My answer" } }, as: :turbo_stream
      end
      assert_response :success
    end

    test "should redirect with alert when message is blank" do
      sign_in_user @user
      post message_architect_session_path(@session), params: { architect_message: { content: "   " } }
      assert_redirected_to architect_session_path(@session)
      assert_equal I18n.t("architect.errors.message_blank"), flash[:alert]
    end

    test "should enforce message rate limit" do
      sign_in_user @user
      ArchitectService::MAX_QA_MESSAGES.times do |i|
        @session.architect_messages.create!(role: i.even? ? :user : :assistant, content: "Msg #{i}", sequence: i)
      end
      post message_architect_session_path(@session), params: { architect_message: { content: "One more" } }
      assert_redirected_to architect_session_path(@session)
      assert_equal I18n.t("architect.errors.rate_limit_messages"), flash[:alert]
    end

    test "should accept when session completed" do
      @session.update!(status: :completed, generated_bio: "New bio", generated_headline: "New headline")
      sign_in_user @user
      patch accept_architect_session_path(@session)
      assert_redirected_to profile_path
      @user.reload
      assert_equal "New bio", @user.bio
      assert_equal "New headline", @user.headline
    end

    test "should redirect with alert when accept on incomplete session" do
      sign_in_user @user
      patch accept_architect_session_path(@session)
      assert_redirected_to architect_session_path(@session)
      assert_equal I18n.t("architect.errors.not_completed"), flash[:alert]
    end

    test "should destroy session when owner" do
      sign_in_user @user
      assert_difference("ArchitectSession.count", -1) do
        delete architect_session_path(@session)
      end
      assert_redirected_to dashboard_path
      assert_equal I18n.t("architect.sessions.destroyed"), flash[:notice]
    end

    private

    def stub_architect_start_session(result)
      original = ArchitectService.method(:start_session)
      ArchitectService.define_singleton_method(:start_session) do |*args, **opts|
        result.respond_to?(:call) ? result.call(*args, **opts) : result
      end
      yield
    ensure
      ArchitectService.define_singleton_method(:start_session) { |*args, **opts| original.call(*args, **opts) }
    end

    def sign_in_user(user)
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }
    end
  end
end
