require "test_helper"

class BlogPostTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user_one)
    @blog_post = blog_posts(:published_post)
    @draft_post = blog_posts(:draft_post)
  end

  # Validation tests
  test "should be valid with valid attributes" do
    blog_post = BlogPost.new(
      title: "Test Post",
      content: "This is test content",
      user: @user
    )
    assert blog_post.valid?
  end

  test "should require title" do
    @blog_post.title = nil
    assert_not @blog_post.valid?
    assert_includes @blog_post.errors[:title], "can't be blank"
  end

  test "should require content" do
    @blog_post.content = nil
    assert_not @blog_post.valid?
    assert_includes @blog_post.errors[:content], "can't be blank"
  end

  test "should require user" do
    @blog_post.user = nil
    assert_not @blog_post.valid?
    assert_includes @blog_post.errors[:user], "must exist"
  end

  test "should limit title length to 255 characters" do
    @blog_post.title = "a" * 256
    assert_not @blog_post.valid?
    assert_includes @blog_post.errors[:title], "is too long (maximum is 255 characters)"
  end

  test "should handle slug generation and uniqueness" do
    # Create and save the original post first
    @blog_post.save!
    original_slug = @blog_post.slug

    # Create another post with same title - FriendlyId should make it unique
    duplicate_post = BlogPost.create!(
      title: @blog_post.title,  # Same title
      content: "Different content",
      user: @user
    )

    # FriendlyId should have generated a different slug
    assert_not_equal original_slug, duplicate_post.slug
    assert duplicate_post.valid?
  end

  test "should require published_at when published" do
    @blog_post.published = true
    @blog_post.published_at = nil
    assert_not @blog_post.valid?
    assert_includes @blog_post.errors[:published_at], "can't be blank when post is published"
  end

  # Slug generation tests
  test "should generate slug from title" do
    blog_post = BlogPost.create!(
      title: "Test Post With Spaces",
      content: "Content",
      user: @user
    )
    assert_equal "test-post-with-spaces", blog_post.slug
  end

  test "should update slug when title changes" do
    @blog_post.update!(title: "New Title")
    assert_equal "new-title", @blog_post.slug
  end

  # Publishing tests
  test "published? should return true for published posts with past published_at" do
    @blog_post.published = true
    @blog_post.published_at = 1.hour.ago
    assert @blog_post.published?
  end

  test "published? should return false for unpublished posts" do
    @blog_post.published = false
    assert_not @blog_post.published?
  end

  test "published? should return false for posts with future published_at" do
    @blog_post.published = true
    @blog_post.published_at = 1.hour.from_now
    assert_not @blog_post.published?
  end

  test "draft? should return opposite of published?" do
    @blog_post.published = true
    @blog_post.published_at = 1.hour.ago
    assert_not @blog_post.draft?

    @blog_post.published = false
    assert @blog_post.draft?
  end

  # Callback tests
  test "should set published_at when publishing" do
    @draft_post.published = true
    @draft_post.save!
    assert_not_nil @draft_post.published_at
    assert @draft_post.published_at <= Time.current
  end

  test "should clear published_at when unpublishing" do
    @blog_post.published = false
    @blog_post.save!
    assert_nil @blog_post.published_at
  end

  test "should generate excerpt if blank" do
    content = "This is a long content that should be truncated for the excerpt. " * 10
    blog_post = BlogPost.create!(
      title: "Test Post",
      content: content,
      user: @user
    )
    assert_not_nil blog_post.excerpt
    assert blog_post.excerpt.length <= 153 # 150 + "..."
    assert blog_post.excerpt.ends_with?("...")
  end

  test "should not overwrite existing excerpt" do
    existing_excerpt = "Custom excerpt"
    blog_post = BlogPost.create!(
      title: "Test Post",
      content: "Long content here",
      excerpt: existing_excerpt,
      user: @user
    )
    assert_equal existing_excerpt, blog_post.excerpt
  end

  # Scope tests
  test "published scope should return only published posts" do
    published_posts = BlogPost.published
    published_posts.each do |post|
      assert post.published
    end
  end

  test "draft scope should return only unpublished posts" do
    draft_posts = BlogPost.draft
    draft_posts.each do |post|
      assert_not post.published
    end
  end

  test "published_posts should return published posts with past published_at" do
    # Create a published post with future published_at
    future_post = BlogPost.create!(
      title: "Future Post",
      content: "Content",
      user: @user,
      published: true,
      published_at: 1.hour.from_now
    )

    published_posts = BlogPost.published_posts
    assert_not_includes published_posts, future_post
    assert_includes published_posts, @blog_post
  end

  test "recent_posts should limit and order by publication date" do
    recent_posts = BlogPost.recent_posts(1)
    assert_equal 1, recent_posts.size

    # Should be ordered by published_at desc
    all_recent = BlogPost.recent_posts(10)
    published_at_dates = all_recent.map(&:published_at).compact
    assert_equal published_at_dates.sort.reverse, published_at_dates
  end

  test "published_before should return posts published before given date" do
    cutoff_date = 2.days.ago
    posts = BlogPost.published_before(cutoff_date)
    posts.each do |post|
      assert post.published_at <= cutoff_date
    end
  end

  test "published_after should return posts published after given date" do
    cutoff_date = 2.days.ago
    posts = BlogPost.published_after(cutoff_date)
    posts.each do |post|
      assert post.published_at >= cutoff_date
    end
  end

  # Content analysis tests
  test "reading_time should calculate based on word count" do
    # 400 words should take 2 minutes (200 words per minute)
    content = ("word " * 400).strip
    blog_post = BlogPost.new(content: content)
    assert_equal 2, blog_post.reading_time
  end

  test "reading_time should round up partial minutes" do
    # 250 words should take 2 minutes (rounded up from 1.25)
    content = ("word " * 250).strip
    blog_post = BlogPost.new(content: content)
    assert_equal 2, blog_post.reading_time
  end

  test "word_count should count words accurately" do
    content = "This is a test with five words"
    blog_post = BlogPost.new(content: content)
    assert_equal 7, blog_post.word_count
  end

  test "word_count should handle empty content" do
    blog_post = BlogPost.new(content: "")
    assert_equal 0, blog_post.word_count
  end

  # URL parameter tests
  test "to_param should return slug" do
    assert_equal @blog_post.slug, @blog_post.to_param
  end

  # Association tests
  test "should belong to user" do
    assert_respond_to @blog_post, :user
    assert_instance_of User, @blog_post.user
  end

  # FriendlyId tests
  test "should find by slug using friendly" do
    found_post = BlogPost.friendly.find(@blog_post.slug)
    assert_equal @blog_post.id, found_post.id
  end

  test "should still find by id using friendly" do
    found_post = BlogPost.friendly.find(@blog_post.id)
    assert_equal @blog_post.id, found_post.id
  end
end
