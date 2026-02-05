# frozen_string_literal: true

require "test_helper"

class ResultParserTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "result_parser@example.com",
      password: "password123",
      username: "resultparser"
    )
    @user.update!(account_status: :active)
  end

  test "profile builder parser splits bio and headline for both goal" do
    session = ArchitectSession.create!(user: @user, goal: "both", mode: "profile_builder", status: :in_progress)
    parser = ResultParser.for("profile_builder")
    bio, headline = parser.parse_finalize(
      text: "BIO:\nBuilt scalable APIs.\n\nHEADLINE:\nBackend Engineer",
      session: session
    )

    assert_equal "Built scalable APIs.", bio
    assert_equal "Backend Engineer", headline
  end

  test "for returns profile builder parser for unknown modes" do
    assert_instance_of ResultParsers::ProfileBuilder, ResultParser.for("unknown_mode")
  end
end
