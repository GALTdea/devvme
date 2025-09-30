require "application_system_test_case"

class UnclaimedProfileUiTest < ApplicationSystemTestCase
  setup do
    @invited_user = users(:invited_user)
  end

  test "displays unclaimed banner for invited users" do
    visit "/#{@invited_user.username}"

    # Should show the unclaimed banner
    assert_selector ".bg-gradient-to-r.from-amber-50", text: "This profile is unclaimed"
    assert_selector "h2", text: "🚨 This profile is unclaimed"

    # Should show claim profile button if invitation is valid
    if @invited_user.invitation_pending? && !@invited_user.invitation_expired?
      assert_selector "a[href*='/invitations/'][href*='/claim']", text: "Claim This Profile"
    end
  end

  test "shows unclaimed status badges in profile header" do
    visit "/#{@invited_user.username}"

    # Should show unclaimed status badge
    assert_selector ".bg-amber-100", text: "Profile Unclaimed"
    assert_selector ".bg-blue-100", text: "Preview Mode"

    # Should NOT show regular status badges
    assert_no_selector ".bg-primary-100", text: "Available for hire"
    assert_no_selector ".bg-secondary-100", text: "3+ years coding"
  end

  test "disables contact buttons for unclaimed profiles" do
    # Add contact email to the invited user for testing
    @invited_user.update!(contact_email: "test@example.com")

    visit "/#{@invited_user.username}"

    # Should show disabled contact button
    assert_selector "button[disabled]", text: "mail --disabled"
    assert_selector "[data-tooltip-target='email-disabled-tooltip']"

    # Should NOT show active contact button
    assert_no_selector "a[href^='mailto:']", text: "mail -s \"hello\""
  end

  test "shows claim profile button in action buttons section" do
    visit "/#{@invited_user.username}"

    # Should show claim profile button in header actions
    if @invited_user.invitation_pending? && !@invited_user.invitation_expired?
      within ".flex.flex-wrap.gap-3.no-print" do
        assert_selector "a[href*='/invitations/'][href*='/claim']", text: "Claim Profile"
      end
    end

    # Should show modified share button for unclaimed profiles
    assert_selector "button", text: "share --preview"
    assert_no_selector "button", text: "share --profile"
  end

  test "shows appropriate empty states for unclaimed profiles" do
    visit "/#{@invited_user.username}"

    # Should show unclaimed-specific empty state
    assert_selector ".text-amber-900", text: "Content Coming Soon"
    assert_selector ".text-amber-700", text: "This profile is waiting to be claimed"
    assert_selector ".bg-amber-100", text: "Profile in preview mode"

    # Should NOT show regular empty state
    assert_no_selector ".text-charcoal-900", text: "No Content Yet"
  end

  test "shows unclaimed visual indicators throughout the profile" do
    visit "/#{@invited_user.username}"

    # Check for amber/warning color scheme throughout
    assert_selector ".border-amber-200" # Banner border
    assert_selector ".bg-amber-100" # Various amber backgrounds
    assert_selector ".text-amber-900" # Amber text colors

    # Check for key visual elements
    assert_selector "svg" # Warning icons
    assert_selector ".animate-pulse" # Pulsing elements for attention
  end
end
