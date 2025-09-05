require "test_helper"

class BlogPerformanceTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user_one)

    # Clean up any existing blog posts for this test
    @user.blog_posts.destroy_all
  end

  def teardown
    # Clean up test data
    @user.blog_posts.destroy_all if @user
  end

  test "public blog index performs well with many posts" do
    # Create many blog posts
    create_many_blog_posts(100)

    # Measure performance of index page
    assert_performance(allocated: 50000) do
      get public_blog_index_url
    end

    assert_response :success
    assert_select "article"
  end

  test "blog post show page performs well" do
    blog_post = create_blog_post_with_long_content

    # Measure performance of show page
    # Increased limit to account for table of contents generation and large content processing
    assert_performance(allocated: 40000) do
      get public_blog_post_url(blog_post)
    end

    assert_response :success
    assert_select ".prose"
  end

  test "admin blog index performs well with many posts" do
    create_many_blog_posts(100)
    sign_in @user

    # Measure performance of admin index
    assert_performance(allocated: 50000) do
      get blog_posts_url
    end

    assert_response :success
  end

  test "search functionality performs well with many posts" do
    create_many_blog_posts(50)

    # Measure search performance
    assert_performance(allocated: 40000) do
      get public_blog_index_url, params: { search: "Ruby" }
    end

    assert_response :success
  end

  test "RSS feed data preparation performs well" do
    create_many_blog_posts(100)

    # Test that RSS data preparation is efficient
    assert_performance(allocated: 30000) do
      @blog_posts = BlogPost.published_posts.includes(:user).limit(20)
    end

    # Verify we have the right data structure
    assert @blog_posts.count <= 20
    assert @blog_posts.all?(&:published?)
  end

  test "pagination works correctly with many posts" do
    create_many_blog_posts(25)

    get public_blog_index_url
    assert_response :success

    # Should have pagination controls for more than 12 posts
    assert_select "#blog-pagination" if BlogPost.published_posts.count > 12
  end

  test "database queries are optimized" do
    create_many_blog_posts(20)

    # Test N+1 query prevention
    # Increased limit to account for visitor tracking and other middleware queries
    assert_queries(15) do # Reasonable number of queries including visitor tracking
      get public_blog_index_url
    end
  end

  test "view counting doesn't affect performance significantly" do
    blog_post = create_blog_post_with_long_content

    # Measure performance with view tracking
    elapsed_time = Benchmark.realtime do
      10.times do
        get public_blog_post_url(blog_post)
      end
    end

    # Should complete 10 requests in reasonable time (accounting for job processing overhead)
    assert elapsed_time < 3.seconds, "View tracking caused performance degradation"
  end

  test "memory usage stays reasonable with large content" do
    # Create posts with increasingly large content
    small_post = create_blog_post_with_content(1000)    # 1KB
    medium_post = create_blog_post_with_content(10000)  # 10KB
    large_post = create_blog_post_with_content(100000)  # 100KB

    # Test memory usage for each
    [small_post, medium_post, large_post].each do |post|
      assert_performance(allocated: 100000) do
        get public_blog_post_url(post)
      end
      assert_response :success
    end
  end

  test "markdown rendering performs well with complex content" do
    content = generate_complex_markdown
    blog_post = BlogPost.create!(
      title: "Complex Markdown Test",
      content: content,
      user: @user,
      published: true,
      published_at: Time.current
    )

    # Test markdown rendering performance
    assert_performance(allocated: 80000) do
      get public_blog_post_url(blog_post)
    end

    assert_response :success
  end

  private

  def create_many_blog_posts(count)
    count.times do |i|
      BlogPost.create!(
        title: "Performance Test Post #{i + 1}",
        content: generate_sample_content(i),
        excerpt: "This is a test excerpt for post #{i + 1}",
        user: @user,
        published: true,
        published_at: i.days.ago,
        views_count: rand(0..1000)
      )
    end
  end

  def create_blog_post_with_long_content
    BlogPost.create!(
      title: "Long Content Performance Test",
      content: generate_long_content,
      user: @user,
      published: true,
      published_at: Time.current
    )
  end

  def create_blog_post_with_content(size_bytes)
    content = "A" * size_bytes
    BlogPost.create!(
      title: "Content Size Test #{size_bytes} bytes",
      content: content,
      user: @user,
      published: true,
      published_at: Time.current
    )
  end

  def generate_sample_content(index)
    languages = ['Ruby', 'JavaScript', 'Python', 'Go', 'Rust']
    topics = ['web development', 'API design', 'testing', 'performance', 'architecture']

    <<~MARKDOWN
      # #{languages.sample} and #{topics.sample}

      This is a sample blog post about #{topics.sample}. It contains various elements
      to test performance and rendering.

      ## Code Example

      ```ruby
      def example_method_#{index}
        puts "Hello from post #{index}"
        yield if block_given?
      end
      ```

      ## List of Features

      - Feature A for #{languages.sample}
      - Feature B for performance testing
      - Feature C for scalability

      ## Conclusion

      This post demonstrates various markdown elements for performance testing.
      The content is generated dynamically to simulate real blog posts.
    MARKDOWN
  end

  def generate_long_content
    content = "# Performance Test with Long Content\n\n"

    8.times do |i|
      content += <<~MARKDOWN
        ## Section #{i + 1}

        This is section #{i + 1} with substantial content to test performance.
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua.

        ```ruby
        def section_#{i + 1}_method
          # This is a code block in section #{i + 1}
          puts "Processing section #{i + 1}"
          (1..15).each { |n| puts n if n % 5 == 0 }
        end
        ```

        ### Subsection #{i + 1}.1

        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi
        ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit
        in voluptate velit esse cillum dolore eu fugiat nulla pariatur.

      MARKDOWN
    end

    content
  end

  def generate_complex_markdown
    <<~MARKDOWN
      # Complex Markdown Performance Test

      This document tests various markdown features for performance analysis.

      ## Tables

      | Feature | Performance | Memory Usage | Complexity |
      |---------|-------------|--------------|------------|
      | Rendering | Fast | Low | Medium |
      | Parsing | Medium | Medium | High |
      | Caching | Fast | High | Low |

      ## Nested Lists

      1. First level
         - Second level
           - Third level
             - Fourth level
               - Fifth level
      2. Back to first level
         1. Numbered second level
         2. Another numbered item
            - Mixed with bullets
            - Another bullet

      ## Code Blocks with Different Languages

      ```ruby
      class ComplexExample
        def initialize(options = {})
          @options = options
          @cache = {}
        end

        def process(data)
          return @cache[data] if @cache.key?(data)
          result = expensive_operation(data)
          @cache[data] = result
          result
        end

        private

        def expensive_operation(data)
          # Simulate complex processing
          sleep(0.1)
          data.reverse
        end
      end
      ```

      ```javascript
      const complexExample = {
        init: function(options) {
          this.options = options || {};
          this.cache = new Map();
        },

        process: async function(data) {
          if (this.cache.has(data)) {
            return this.cache.get(data);
          }

          const result = await this.expensiveOperation(data);
          this.cache.set(data, result);
          return result;
        },

        expensiveOperation: function(data) {
          return new Promise(resolve => {
            setTimeout(() => {
              resolve(data.split('').reverse().join(''));
            }, 100);
          });
        }
      };
      ```

      ## Headers for TOC Generation

      ### Performance Considerations
      #### Memory Management
      ##### Garbage Collection
      ###### Optimization Strategies

      ### Scalability Factors
      #### Database Queries
      ##### Indexing Strategy

      ## Links and References

      Check out [Ruby on Rails](https://rubyonrails.org) for more information.
      Also see [GitHub](https://github.com) for code examples.

      ## Emphasis and Formatting

      This paragraph contains **bold text**, *italic text*, `inline code`,
      ~~strikethrough text~~, and ==highlighted text==.

      > This is a blockquote that contains multiple lines of text.
      > It should be rendered properly even with complex content around it.
      > The performance should remain stable regardless of content complexity.

      ## Mathematical Expressions (if supported)

      The formula for performance optimization is: O(n log n) where n is the
      number of blog posts being processed.

      ## Conclusion

      This complex markdown document tests various rendering scenarios to ensure
      the blog system maintains good performance even with feature-rich content.
    MARKDOWN
  end

  # Custom assertion for performance testing
  def assert_performance(allocated:, &block)
    # Simple memory allocation check
    initial_objects = ObjectSpace.count_objects[:TOTAL]

    result = yield

    final_objects = ObjectSpace.count_objects[:TOTAL]
    objects_allocated = final_objects - initial_objects

    assert objects_allocated < allocated,
           "Too many objects allocated: #{objects_allocated} (limit: #{allocated})"

    result
  end

  # Custom assertion for database query counting
  def assert_queries(expected_count, &block)
    query_count = 0

    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      query_count += 1 unless args.last[:name] == "SCHEMA"
    end

    yield

    ActiveSupport::Notifications.unsubscribe(subscriber)

    assert query_count <= expected_count,
           "Expected at most #{expected_count} queries, got #{query_count}"
  end
end
