require "test_helper"

class WaitingListControllerTest < ActionDispatch::IntegrationTest
  test "should get new waiting list page" do
    get waiting_list_path
    assert_response :success
    assert_select "form"
    assert_select "input[type=email][name='waiting_list_entry[email]']"
  end

  test "should create waiting list entry with valid data" do
    assert_difference('WaitingListEntry.count', 1) do
      post waiting_list_path, params: {
        waiting_list_entry: {
          email: "newuser@example.com",
          full_name: "New User"
        }
      }
    end

    assert_redirected_to waiting_list_success_path
    assert_equal "You've been added to the waiting list!", flash[:notice]
  end

  test "should not create waiting list entry with invalid email" do
    assert_no_difference('WaitingListEntry.count') do
      post waiting_list_path, params: {
        waiting_list_entry: {
          email: "invalid-email",
          full_name: "Test User"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create duplicate pending entries" do
    WaitingListEntry.create!(email: "duplicate@example.com")

    assert_no_difference('WaitingListEntry.count') do
      post waiting_list_path, params: {
        waiting_list_entry: {
          email: "duplicate@example.com",
          full_name: "Duplicate User"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should accept entry without full name" do
    assert_difference('WaitingListEntry.count', 1) do
      post waiting_list_path, params: {
        waiting_list_entry: {
          email: "noname@example.com"
        }
      }
    end

    assert_redirected_to waiting_list_success_path
  end

  test "should capture source parameter" do
    post waiting_list_path, params: {
      waiting_list_entry: {
        email: "source@example.com"
      },
      source: "homepage"
    }

    entry = WaitingListEntry.find_by(email: "source@example.com")
    assert_equal "homepage", entry.source
  end

  test "should show success page" do
    get waiting_list_success_path
    assert_response :success
    assert_select "h1", text: /on the List/i
  end
end
