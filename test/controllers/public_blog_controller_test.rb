require "test_helper"

class PublicBlogControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get public_blog_index_url
    assert_response :success
  end

  test "should get show" do
    get public_blog_show_url
    assert_response :success
  end
end
