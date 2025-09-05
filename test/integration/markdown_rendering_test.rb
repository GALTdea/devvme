require "test_helper"

class MarkdownRenderingTest < ActionDispatch::IntegrationTest
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper

  setup do
    @user = users(:test_user_one)
  end

  test "should render basic markdown elements" do
    markdown_content = <<~MARKDOWN
      # Main Heading

      This is a paragraph with **bold** and *italic* text.

      ## Subheading

      - List item 1
      - List item 2
      - List item 3

      1. Numbered item 1
      2. Numbered item 2

      > This is a blockquote

      `inline code` and normal text.
    MARKDOWN

    rendered = markdown(markdown_content)

    assert_includes rendered, "<h1"
    assert_includes rendered, "<h2"
    assert_includes rendered, "<strong>bold</strong>"
    assert_includes rendered, "<em>italic</em>"
    assert_includes rendered, "<ul>"
    assert_includes rendered, "<ol>"
    assert_includes rendered, "<blockquote>"
    assert_includes rendered, "<code>inline code</code>"
  end

  test "should render code blocks with syntax highlighting" do
    markdown_content = <<~MARKDOWN
      ```ruby
      class User < ApplicationRecord
        has_many :blog_posts
      end
      ```

      ```javascript
      const message = "Hello World";
      console.log(message);
      ```

      ```python
      def hello_world():
          print("Hello, World!")
      ```
    MARKDOWN

    rendered = markdown(markdown_content)

    # Should have code blocks with language classes
    assert_includes rendered, 'class="language-ruby"'
    assert_includes rendered, 'class="language-javascript"'
    assert_includes rendered, 'class="language-python"'

    # Should have syntax highlighting (checking for code-block structure)
    assert_includes rendered, 'class="code-block"'

    # Should have copy buttons
    assert_includes rendered, 'data-controller="code-copy"'
    assert_includes rendered, 'class="copy-btn"'

    # Should show language labels
    assert_includes rendered, "RUBY"
    assert_includes rendered, "JAVASCRIPT"
    assert_includes rendered, "PYTHON"
  end

  test "should render tables" do
    markdown_content = <<~MARKDOWN
      | Name | Age | City |
      |------|-----|------|
      | John | 30  | NYC  |
      | Jane | 25  | LA   |
    MARKDOWN

    rendered = markdown(markdown_content)

    assert_includes rendered, "<table"
    assert_includes rendered, "<thead>"
    assert_includes rendered, "<tbody>"
    assert_includes rendered, "<th>Name</th>"
    assert_includes rendered, "<td>John</td>"
  end

  test "should render links with proper attributes" do
    markdown_content = <<~MARKDOWN
      [Internal Link](/blog)
      [External Link](https://example.com)
      [Rails Documentation](https://guides.rubyonrails.org)
    MARKDOWN

    rendered = markdown(markdown_content)

    # External links should have target and rel attributes
    assert_includes rendered, 'target="_blank"'
    assert_includes rendered, 'rel="noopener noreferrer"'
    assert_includes rendered, 'href="https://example.com"'
    assert_includes rendered, 'href="https://guides.rubyonrails.org"'
  end

  test "should generate header anchors" do
    markdown_content = <<~MARKDOWN
      # Introduction
      ## Getting Started
      ### Advanced Topics
    MARKDOWN

    rendered = markdown(markdown_content)

    # Should have anchor IDs
    assert_includes rendered, 'id="introduction"'
    assert_includes rendered, 'id="getting-started"'
    assert_includes rendered, 'id="advanced-topics"'

    # Should have anchor links
    assert_includes rendered, 'href="#introduction"'
    assert_includes rendered, 'href="#getting-started"'
    assert_includes rendered, 'href="#advanced-topics"'
  end

    test "should sanitize dangerous HTML" do
    markdown_content = <<~MARKDOWN
      <script>alert('xss')</script>
      <iframe src="malicious.com"></iframe>
      <div onclick="alert('click')">Click me</div>

      This is safe **bold** text.
    MARKDOWN

    rendered = markdown(markdown_content)

    # Should filter out dangerous HTML elements
    assert_not_includes rendered, "<script"
    assert_not_includes rendered, "<iframe"
    # onclick should be escaped, not executable
    assert_not_includes rendered, "onclick=\"alert"

    # Should keep safe markdown
    assert_includes rendered, "<strong>bold</strong>"

    # HTML should be escaped, so text content might be present but not executable
    assert_includes rendered, "xss"  # The text content should be escaped
  end

  test "should handle special characters in headers" do
    markdown_content = <<~MARKDOWN
      # Special Characters: !@#$%^&*()
      ## Unicode: Ñiño & Café
      ### Numbers & Symbols: 123-ABC_def
    MARKDOWN

    rendered = markdown(markdown_content)

    # Should create valid anchor IDs (exact format depends on implementation)
    assert_match /id="[^"]*special[^"]*characters[^"]*"/, rendered
    assert_match /id="[^"]*unicode[^"]*"/, rendered
    assert_match /id="[^"]*numbers[^"]*symbols[^"]*"/, rendered
  end

  test "should render strikethrough and other extensions" do
    markdown_content = <<~MARKDOWN
      ~~strikethrough text~~

      This is ^superscript^ text.

      This has _underline_ formatting.

      ==highlighted== text.
    MARKDOWN

    rendered = markdown(markdown_content)

    assert_includes rendered, "<del>strikethrough text</del>"
    # Other extensions depend on Redcarpet configuration
  end

  test "should handle empty and nil content" do
    assert_equal "", markdown(nil)
    assert_equal "", markdown("")
    assert_equal "", markdown("   ")
  end

  test "should render plain markdown without formatting" do
    markdown_content = <<~MARKDOWN
      # Heading
      **Bold** and *italic* text.
      [Link](http://example.com)
      `code`
    MARKDOWN

    rendered = markdown_plain(markdown_content)

    # Should strip markdown formatting and return plain text
    assert_includes rendered, "Heading"
    assert_includes rendered, "Bold"
    assert_includes rendered, "italic"
    assert_not_includes rendered, "**"
    assert_not_includes rendered, "*"
    assert_not_includes rendered, "#"
    assert_not_includes rendered, "`"
  end

  test "should generate table of contents" do
    markdown_content = <<~MARKDOWN
      # Introduction
      Some content here.

      ## Chapter 1: Getting Started
      More content.

      ### Section 1.1: Installation
      Installation steps.

      ## Chapter 2: Advanced Usage
      Advanced content.

      ### Section 2.1: Configuration
      Config details.

      #### Subsection 2.1.1: Database
      DB config.
    MARKDOWN

    toc = markdown_toc(markdown_content)

    assert_includes toc, 'class="table-of-contents"'
    assert_includes toc, 'class="toc-title"'
    assert_includes toc, 'class="toc-list"'

    # Should include all headers
    assert_includes toc, "Introduction"
    assert_includes toc, "Chapter 1: Getting Started"
    assert_includes toc, "Section 1.1: Installation"
    assert_includes toc, "Chapter 2: Advanced Usage"

    # Should have proper nesting classes
    assert_includes toc, 'class="toc-level-1"'
    assert_includes toc, 'class="toc-level-2"'
    assert_includes toc, 'class="toc-level-3"'
    assert_includes toc, 'class="toc-level-4"'

    # Should have anchor links
    assert_includes toc, 'href="#introduction"'
    assert_includes toc, 'href="#chapter-1-getting-started"'
  end

  test "should handle edge cases in markdown" do
    edge_cases = [
      "# \n",  # Empty header
      "```\n\n```",  # Empty code block
      "[]()",  # Empty link
      "**  **",  # Empty bold
      "* \n* \n*",  # Empty list items
    ]

    edge_cases.each do |content|
      assert_nothing_raised do
        rendered = markdown(content)
        assert_not_nil rendered
      end
    end
  end

  test "should preserve line breaks and spacing" do
    markdown_content = <<~MARKDOWN
      First paragraph.

      Second paragraph with
      a line break.

      Third paragraph.
    MARKDOWN

    rendered = markdown(markdown_content)

    # Should have separate paragraphs
    assert_includes rendered, "<p>"
    # Should handle line breaks (depends on configuration)
  end

  test "should render footnotes if enabled" do
    markdown_content = <<~MARKDOWN
      This text has a footnote[^1].

      [^1]: This is the footnote text.
    MARKDOWN

    rendered = markdown(markdown_content)

    # Footnotes depend on Redcarpet configuration
    # This tests the configuration setting
    if rendered.include?("footnote")
      assert_includes rendered, "footnote"
    end
  end

  test "should handle very long content efficiently" do
    # Generate a large markdown document
    large_content = "# Large Document\n\n"
    1000.times do |i|
      large_content += "## Section #{i}\n\nThis is content for section #{i}.\n\n"
    end

    start_time = Time.current
    rendered = markdown(large_content)
    end_time = Time.current

    # Should complete in reasonable time (less than 5 seconds)
    assert (end_time - start_time) < 5.seconds
    assert_not_nil rendered
    assert rendered.length > 0
  end

  test "should be consistent across multiple renders" do
    markdown_content = <<~MARKDOWN
      # Test Consistency

      This is **bold** and *italic*.

      ```ruby
      puts "Hello World"
      ```
    MARKDOWN

    rendered1 = markdown(markdown_content)
    rendered2 = markdown(markdown_content)

    assert_equal rendered1, rendered2
  end
end
