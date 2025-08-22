require "application_system_test_case"

class ShareButtonTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
  end

  test "share button appears on private profile page" do
    sign_in_as(@user)
    visit profile_path

    assert_selector "[data-controller='share-button']"
    assert_selector "button[data-action='click->share-button#share']", text: "Share Profile"
  end

  test "share button appears on public profile page" do
    visit public_profile_path(@user.username)

    assert_selector "[data-controller='share-button']"
    assert_selector "button[data-action='click->share-button#share']", text: "Share Profile"
  end

  test "share button has correct data attributes on private profile" do
    sign_in_as(@user)
    visit profile_path

    share_controller = find("[data-controller='share-button']")

    # Should have URL and title values
    assert share_controller["data-share-button-url-value"].present?
    assert_equal "#{@user.display_name}'s Profile", share_controller["data-share-button-title-value"]
  end

  test "share button has correct data attributes on public profile" do
    visit public_profile_path(@user.username)

    share_controller = find("[data-controller='share-button']")

    # Should have URL and title values
    assert share_controller["data-share-button-url-value"].present?
    assert_equal "#{@user.display_name}'s Profile", share_controller["data-share-button-title-value"]
  end

  test "clicking share button shows notification when Web Share API not available" do
    # Most headless browsers don't support Web Share API, so this tests the fallback
    sign_in_as(@user)
    visit profile_path

    # Mock clipboard API to avoid permissions issues in headless browser
    page.execute_script(<<~JS)
      navigator.clipboard = {
        writeText: function(text) {
          window.copiedText = text;
          return Promise.resolve();
        }
      };
    JS

    click_button "Share Profile"

    # Should show success notification
    assert_selector ".fixed.top-4.right-4.bg-green-500", text: "Profile URL copied to clipboard!"

    # Verify the URL was "copied"
    copied_text = page.evaluate_script("window.copiedText")
    assert copied_text.present?
  end

  test "share button handles clipboard failure gracefully" do
    sign_in_as(@user)
    visit profile_path

    # Mock clipboard API to fail
    page.execute_script(<<~JS)
      navigator.clipboard = {
        writeText: function(text) {
          return Promise.reject(new Error('Clipboard access denied'));
        }
      };
    JS

    click_button "Share Profile"

    # Should show error notification
    assert_selector ".fixed.top-4.right-4.bg-red-500", text: "Failed to copy URL"
  end

  test "notification disappears after timeout" do
    sign_in_as(@user)
    visit profile_path

    # Mock clipboard API
    page.execute_script(<<~JS)
      navigator.clipboard = {
        writeText: function(text) {
          return Promise.resolve();
        }
      };
    JS

    click_button "Share Profile"

    # Should show notification initially
    assert_selector ".fixed.top-4.right-4.bg-green-500", text: "Profile URL copied to clipboard!"

    # Wait for notification to fade out (should happen after 3 seconds + fade transition)
    using_wait_time(5) do
      assert_no_selector ".fixed.top-4.right-4.bg-green-500"
    end
  end

  test "share button works with Web Share API when available" do
    sign_in_as(@user)
    visit profile_path

    # Mock Web Share API
    page.execute_script(<<~JS)
      navigator.share = function(data) {
        window.sharedData = data;
        return Promise.resolve();
      };
    JS

    click_button "Share Profile"

    # Verify Web Share API was called with correct data
    shared_data = page.evaluate_script("window.sharedData")
    assert_equal "#{@user.display_name}'s Profile", shared_data["title"]
    assert shared_data["url"].present?

    # Should not show fallback notification since Web Share API "worked"
    assert_no_selector ".fixed.top-4.right-4"
  end

  test "share button handles Web Share API rejection gracefully" do
    sign_in_as(@user)
    visit profile_path

    # Mock Web Share API to reject (user cancelled)
    page.execute_script(<<~JS)
      navigator.share = function(data) {
        return Promise.reject(new Error('Share cancelled'));
      };
      navigator.clipboard = {
        writeText: function(text) {
          window.fallbackCalled = true;
          return Promise.resolve();
        }
      };
    JS

    click_button "Share Profile"

    # Should fall back to clipboard
    fallback_called = page.evaluate_script("window.fallbackCalled")
    assert fallback_called

    # Should show fallback notification
    assert_selector ".fixed.top-4.right-4.bg-green-500", text: "Profile URL copied to clipboard!"
  end

  private

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Log in"
  end
end
