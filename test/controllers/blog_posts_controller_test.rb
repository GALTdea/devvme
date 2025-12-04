require "test_helper"

class BlogPostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:test_user_one)
    @blog_post = blog_posts(:published_post)
    sign_in @user
  end

  test "should get index" do
    get blog_posts_url
    assert_response :success
    assert_select "h1", "Blog Posts"
  end

  test "should get new" do
    get new_blog_post_url
    assert_response :success
    assert_select "h1", "New Blog Post"
  end

  test "should create blog_post as draft" do
    assert_difference("BlogPost.count") do
      post blog_posts_url, params: {
        blog_post: {
          title: "Test Blog Post",
          content: "This is test content",
          excerpt: "Test excerpt",
          published: false
        },
        commit: "Save Draft"
      }
    end

    blog_post = BlogPost.last
    assert_not blog_post.published?
    assert_redirected_to blog_post_url(blog_post)
    assert_equal "Blog post draft was saved successfully.", flash[:notice]
  end

  test "should create blog_post as published" do
    assert_difference("BlogPost.count") do
      post blog_posts_url, params: {
        blog_post: {
          title: "Published Test Post",
          content: "This is published content",
          excerpt: "Published excerpt",
          published: true
        },
        commit: "Publish Post"
      }
    end

    blog_post = BlogPost.last
    assert blog_post.published?
    assert_not_nil blog_post.published_at
    assert_redirected_to blog_post_url(blog_post)
    assert_equal "Blog post was published successfully!", flash[:notice]
  end

  test "should show blog_post" do
    get blog_post_url(@blog_post)
    assert_response :success
    assert_select "h1", @blog_post.title
  end

  test "should get edit" do
    get edit_blog_post_url(@blog_post)
    assert_response :success
    assert_select "h1", "Edit Blog Post"
  end

  test "should update blog_post" do
    patch blog_post_url(@blog_post), params: {
      blog_post: {
        title: "Updated Title",
        content: @blog_post.content,
        excerpt: @blog_post.excerpt,
        published: @blog_post.published
      }
    }

    @blog_post.reload
    assert_equal "Updated Title", @blog_post.title
    assert_redirected_to blog_post_url(@blog_post)
  end

  test "should destroy blog_post" do
    assert_difference("BlogPost.count", -1) do
      delete blog_post_url(@blog_post)
    end

    assert_redirected_to blog_posts_url
    assert_equal "Blog post was successfully deleted.", flash[:notice]
  end

  test "should filter by status" do
    get blog_posts_url, params: { status: "published" }
    assert_response :success

    get blog_posts_url, params: { status: "draft" }
    assert_response :success
  end

  test "should search blog posts" do
    get blog_posts_url, params: { search: "Rails" }
    assert_response :success
  end

  test "should not allow access to other users blog posts" do
    other_user = users(:test_user_two)
    other_blog_post = blog_posts(:another_published_post)

    get edit_blog_post_url(other_blog_post)
    assert_redirected_to blog_posts_url
    assert_equal "You can only manage your own blog posts.", flash[:alert]
  end

  test "should require authentication" do
    sign_out @user

    get blog_posts_url
    assert_redirected_to new_user_session_url
  end

  test "should handle autosave" do
    post autosave_blog_post_url(@blog_post), params: {
      blog_post: {
        title: "Autosaved Title",
        content: "Autosaved content",
        excerpt: "Autosaved excerpt"
      }
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    assert_equal "Draft saved", json_response["message"]
  end

  test "should handle invalid blog post creation" do
    post blog_posts_url, params: {
      blog_post: {
        title: "", # Invalid - title is required
        content: "Content",
        excerpt: "Excerpt"
      }
    }

    assert_response :unprocessable_content
    assert_select "h1", "New Blog Post"
  end

  test "should handle invalid blog post update" do
    patch blog_post_url(@blog_post), params: {
      blog_post: {
        title: "", # Invalid - title is required
        content: @blog_post.content,
        excerpt: @blog_post.excerpt
      }
    }

    assert_response :unprocessable_content
    assert_select "h1", "Edit Blog Post"
  end
end
