require "test_helper"

class ProjectResumeBullets::RateLimiterTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    ProjectResumeBullets::RateLimiter::FALLBACK_STORE.clear
    @user = users(:test_user_one)
    @project = projects(:test_project_one)
  end

  test "allows first request and then enforces cooldown" do
    limiter = ProjectResumeBullets::RateLimiter.new

    allowed, message = limiter.allowed?(user: @user, project: @project)
    assert_equal true, allowed
    assert_nil message

    limiter.track!(user: @user, project: @project)

    allowed_after, message_after = limiter.allowed?(user: @user, project: @project)
    assert_equal false, allowed_after
    assert_match(/wait a few seconds/i, message_after)
  end
end
