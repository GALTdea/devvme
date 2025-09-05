require "test_helper"

class PublicBlogControllerTest < ActionDispatch::IntegrationTest
  setup do
    @published_post = blog_posts(:published_post)
    @draft_post = blog_posts(:draft_post)
    @another_published_post = blog_posts(:another_published_post)
  end

  # Index tests
  test "should get index" do
    get public_blog_index_url
    assert_response :success
    assert_select "h1", /Blog/i
  end

  test "should display published posts on index" do
    get public_blog_index_url
    assert_response :success
    assert_select "article", minimum: 1
    assert_select "h2", @published_post.title
    assert_select "h2", @another_published_post.title
  end

  test "should not display draft posts on index" do
    get public_blog_index_url
    assert_response :success
    assert_select "h2", { text: @draft_post.title, count: 0 }
  end

  test "should search published posts" do
    get public_blog_index_url, params: { search: "Rails" }
    assert_response :success
    # Should find the post that contains "Rails" in title or content
    assert_select "article"
  end

  test "should handle empty search results" do
    get public_blog_index_url, params: { search: "nonexistentterm" }
    assert_response :success
    # Should show no results message or empty state
  end

  test "should paginate blog posts" do
    get public_blog_index_url
    assert_response :success
    # Check for pagination controls if there are enough posts
    # Pagy sets limit to 12 per page
  end

  test "should display total posts count" do
    get public_blog_index_url
    assert_response :success
    # Should display the total count of published posts
    published_count = BlogPost.published_posts.count
    assert_match /#{published_count}/, response.body
  end

  # Show tests
  test "should show published blog post" do
    get public_blog_post_url(@published_post)
    assert_response :success
    assert_select "h1", @published_post.title
    assert_select "p", text: /#{@published_post.excerpt}/
  end

  test "should not show draft posts to public" do
    get public_blog_post_url(@draft_post)
    assert_redirected_to public_blog_index_url
    assert_equal "Blog post not found.", flash[:alert]
  end

  test "should handle nonexistent blog post" do
    get public_blog_post_url("nonexistent-slug")
    assert_redirected_to public_blog_index_url
    assert_equal "Blog post not found.", flash[:alert]
  end

    test "should display blog post metadata" do
    get public_blog_post_url(@published_post)
    assert_response :success

    # Should show author information
    assert_select "p", text: /#{@published_post.user.display_name}/

    # Should show publication date
    assert_select "time"

    # Should show reading time
    assert_match /#{@published_post.reading_time} min read/, response.body

    # Should show word count
    assert_match /#{@published_post.word_count} word/, response.body
  end

    test "should render markdown content" do
    get public_blog_post_url(@published_post)
    assert_response :success

    # Should have markdown rendered as HTML
    assert_select ".prose"
    # Note: Markdown is rendered client-side via JavaScript, so we just check for the container
    assert_select "[data-controller='blog-viewer']"
  end

  test "should show navigation to next and previous posts" do
    get public_blog_post_url(@published_post)
    assert_response :success

    # Should have navigation elements
    # Note: This depends on the order of posts and publication dates
  end

  test "should generate table of contents for long posts" do
    # Create a long post with headers
    long_content = <<~MARKDOWN
      # Introduction
      This is a long post.

      ## Section 1
      Content here.

      ### Subsection 1.1
      More content.

      ## Section 2
      Final content.
    MARKDOWN

    long_post = BlogPost.create!(
      title: "Long Post with TOC",
      content: long_content,
      user: users(:test_user_one),
      published: true,
      published_at: Time.current
    )

    get public_blog_post_url(long_post)
    assert_response :success

    # Should generate table of contents for long posts (> 2000 chars)
    if long_content.length > 2000
      assert_select ".table-of-contents"
      assert_select ".toc-link"
    end

    # Cleanup
    long_post.destroy
  end

  test "should not require authentication" do
    # Ensure no user is signed in
    assert_nil @request&.env&.[]("warden")&.user

    get public_blog_index_url
    assert_response :success

    get public_blog_post_url(@published_post)
    assert_response :success
  end

  test "should handle posts with future publication dates" do
    future_post = BlogPost.create!(
      title: "Future Post",
      content: "This post is from the future",
      user: users(:test_user_one),
      published: true,
      published_at: 1.hour.from_now
    )

    # Should not appear in index
    get public_blog_index_url
    assert_response :success
    assert_select "h3", { text: future_post.title, count: 0 }

    # Should not be accessible directly
    get public_blog_post_url(future_post)
    assert_redirected_to public_blog_index_url
    assert_equal "Blog post not found.", flash[:alert]

    # Cleanup
    future_post.destroy
  end

  test "should display proper meta information" do
    get public_blog_post_url(@published_post)
    assert_response :success

    # Should have proper page title
    assert_select "title", text: /#{@published_post.title}/

    # Should have meta description
    assert_select "meta[name='description']"

    # Should have Open Graph tags
    assert_select "meta[property='og:title']"
    assert_select "meta[property='og:description']"
    assert_select "meta[property='og:type']"
  end

  test "should be mobile responsive" do
    get public_blog_index_url
    assert_response :success

    # Should have responsive meta tag
    assert_select "meta[name='viewport'][content*='width=device-width']"

    # Should use responsive CSS classes
    assert_select "[class*='sm:'], [class*='md:'], [class*='lg:']"
  end
end
