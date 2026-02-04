# frozen_string_literal: true

require "test_helper"

class ArchitectServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "arch_svc@example.com",
      password: "password123",
      username: "archsvc",
      full_name: "Arch Service User",
      bio: "A developer",
      headline: "Dev"
    )
    @user.update!(account_status: :active)
  end

  test "build_context returns user_profile and projects" do
    context = ArchitectService.build_context(@user)
    assert context.is_a?(Hash)
    assert context.key?("user_profile")
    assert_equal @user.full_name, context["user_profile"]["full_name"]
    assert_equal @user.bio, context["user_profile"]["bio"]
    assert context.key?("projects")
    assert context["projects"].is_a?(Array)
  end

  test "build_context includes pasted_content when given" do
    context = ArchitectService.build_context(@user, "Pasted text here")
    assert_equal "Pasted text here", context["pasted_content"]
  end

  test "build_context omits pasted_content when blank" do
    context = ArchitectService.build_context(@user, "  ")
    assert_not context.key?("pasted_content")
  end

  test "build_context includes github when GitHubContextService returns data" do
    github_data = {
      "profile" => { "login" => "johndoe", "bio" => "Ruby dev" },
      "repos" => [{ "name" => "my-app", "description" => "A Rails app" }],
      "readmes" => {}
    }
    @user.update!(github_url: "https://github.com/johndoe")
    GitHubContextService.stub(:fetch_for_user, github_data) do
      context = ArchitectService.build_context(@user)
      assert context.key?("github")
      assert_equal github_data, context["github"]
    end
  end

  test "build_context omits github when user has no github_url" do
    context = ArchitectService.build_context(@user)
    assert_not context.key?("github")
  end

  test "start_session raises MissingApiKeysError when OpenAI key is blank" do
    ArchitectService.stub(:openai_api_key, nil) do
      assert_raises(ArchitectService::MissingApiKeysError) do
        ArchitectService.start_session(@user, "both")
      end
    end
  end

  test "reply raises ArgumentError when session is not in_progress" do
    session = ArchitectSession.create!(user: @user, goal: "both", status: :completed)
    assert_raises(ArgumentError, "session must be in_progress") do
      ArchitectService.reply(session)
    end
  end

  test "reply with mocked OpenAI creates assistant message" do
    session = ArchitectSession.create!(user: @user, goal: "both", status: :in_progress)
    mock_response = { "choices" => [{ "message" => { "content" => "What is your job title?" } }] }
    client = Minitest::Mock.new
    client.expect(:chat, mock_response, [Hash])

    ArchitectService.stub(:openai_api_key, "sk-test") do
      OpenAI::Client.stub(:new, client) do
        msg, complete = ArchitectService.reply(session)
        assert msg.present?
        assert msg.message_assistant?
        assert_equal "What is your job title?", msg.content
        assert_not complete
      end
    end
    client.verify
  end

  test "reply when message count at MAX_QA_MESSAGES returns interview_complete" do
    session = ArchitectSession.create!(user: @user, goal: "both", status: :in_progress)
    ArchitectService::MAX_QA_MESSAGES.times do |i|
      session.architect_messages.create!(role: i.even? ? :user : :assistant, content: "Msg #{i}", sequence: i)
    end
    msg, complete = ArchitectService.reply(session)
    assert_nil msg
    assert complete
  end

  test "finalize raises ArgumentError when session is not in_progress" do
    session = ArchitectSession.create!(user: @user, goal: "both", status: :completed)
    assert_raises(ArgumentError, "session must be in_progress") do
      ArchitectService.finalize(session)
    end
  end

  test "finalize with mocked Anthropic updates session" do
    session = ArchitectSession.create!(user: @user, goal: "both", status: :in_progress)
    session.architect_messages.create!(role: :assistant, content: "Hi", sequence: 0)
    session.architect_messages.create!(role: :user, content: "Hello", sequence: 1)
    text_block = Struct.new(:text).new("BIO:\nBio text here.\n\nHEADLINE:\nHeadline here.")
    mock_create_response = Struct.new(:content).new([text_block])
    mock_messages = Minitest::Mock.new
    mock_messages.expect(:create, mock_create_response)
    anthropic_client = Minitest::Mock.new
    anthropic_client.expect(:messages, mock_messages)

    ArchitectService.stub(:anthropic_api_key, "sk-ant-test") do
      Anthropic::Client.stub(:new, anthropic_client) do
        result = ArchitectService.finalize(session)
        assert result
      end
    end
    mock_messages.verify
    anthropic_client.verify
    session.reload
    assert session.completed?
    assert_equal "Bio text here.", session.generated_bio
    assert_equal "Headline here.", session.generated_headline
  end
end
