module ApplicationHelper
  require "redcarpet"
  require "rouge"
  require "rouge/plugins/redcarpet"
  include Pagy::Frontend

  # Markdown renderer with syntax highlighting
  class CustomHTMLRenderer < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper

    def initialize(options = {})
      super(options.merge(
        filter_html: true,
        no_images: false,
        no_links: false,
        no_styles: true,
        escape_html: true,
        hard_wrap: true,
        link_attributes: { target: "_blank", rel: "noopener noreferrer" }
      ))
    end

    def block_code(code, language)
      lexer = Rouge::Lexer.find(language) || Rouge::Lexers::PlainText
      formatter = Rouge::Formatters::HTML.new(
        css_class: "highlight",
        line_numbers: true,
        wrap: false
      )

      content_tag :div, class: "code-block", data: { controller: "code-copy", 'code-copy-code-value': code } do
        content_tag :div, class: "code-header" do
          content_tag(:span, language&.upcase || "CODE", class: "language-label") +
          content_tag(:button, "Copy", class: "copy-btn",
            data: { 'code-copy-target': "button", action: "click->code-copy#copy" })
        end +
        content_tag(:pre, class: "language-#{language}") do
          content_tag(:code, formatter.format(lexer.lex(code)).html_safe, class: "language-#{language}")
        end
      end
    end

    def header(text, header_level)
      # Add anchor links to headers for better navigation
      anchor = text.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")
      content_tag("h#{header_level}", id: anchor, class: "heading-#{header_level}") do
        content_tag(:a, text, href: "##{anchor}", class: "header-link")
      end
    end
  end

  # Main markdown rendering method
  def markdown(text)
    return "" if text.blank?

    renderer = CustomHTMLRenderer.new
    markdown_processor = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      highlight: true,
      footnotes: true,
      space_after_headers: true
    )

    markdown_processor.render(text).html_safe
  end

  # Render markdown without custom formatting (for excerpts)
  def markdown_plain(text)
    return "" if text.blank?

    # Strip markdown syntax first
    plain_text = text.gsub(/[#*`_\[\]()!]/, "")
                    .gsub(/\n+/, " ")
                    .strip

    # Return plain text without HTML
    plain_text
  end

  # Extract reading time from markdown content
  def reading_time(content)
    return 0 if content.blank?

    word_count = content.split.size
    (word_count / 200.0).ceil
  end

  # Generate table of contents from markdown headers
  def markdown_toc(text)
    return "" if text.blank?

    headers = []
    text.scan(/^(\#{1,6})\s+(.+)$/) do |level, title|
      anchor = title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")
      headers << {
        level: level.length,
        title: title.strip,
        anchor: anchor
      }
    end

    return "" if headers.empty?

    content_tag :nav, class: "table-of-contents" do
      content_tag(:h3, "Table of Contents", class: "toc-title") +
      content_tag(:ul, class: "toc-list") do
        headers.map do |header|
          content_tag :li, class: "toc-level-#{header[:level]}" do
            link_to header[:title], "##{header[:anchor]}", class: "toc-link"
          end
        end.join.html_safe
      end
    end
  end

  # SEO and Meta Tag Helpers
  def page_title(title = nil)
    base_title = "Devvme App"
    if title.present?
      content_for :title, "#{title} | #{base_title}"
      title
    else
      base_title
    end
  end

  def meta_description(description)
    content_for :meta_description, truncate(strip_tags(description), length: 160)
  end

  def meta_keywords(keywords)
    content_for :meta_keywords, keywords.is_a?(Array) ? keywords.join(", ") : keywords
  end

  def open_graph_tags(title: nil, description: nil, image: nil, url: nil, type: "website")
    content_for :open_graph do
      tags = []
      tags << tag.meta(property: "og:title", content: title) if title
      tags << tag.meta(property: "og:description", content: description) if description
      tags << tag.meta(property: "og:image", content: image) if image
      tags << tag.meta(property: "og:url", content: url) if url
      tags << tag.meta(property: "og:type", content: type)
      tags << tag.meta(property: "og:site_name", content: "Devvme App")
      tags.join.html_safe
    end
  end

  def twitter_card_tags(title: nil, description: nil, image: nil)
    content_for :twitter_cards do
      tags = []
      tags << tag.meta(name: "twitter:card", content: "summary_large_image")
      tags << tag.meta(name: "twitter:title", content: title) if title
      tags << tag.meta(name: "twitter:description", content: description) if description
      tags << tag.meta(name: "twitter:image", content: image) if image
      tags.join.html_safe
    end
  end

  def blog_post_schema(blog_post)
    content_for :structured_data do
      schema = {
        "@context": "https://schema.org",
        "@type": "BlogPosting",
        "headline": blog_post.title,
        "description": blog_post.excerpt,
        "author": {
          "@type": "Person",
          "name": blog_post.user.email # You might want to add a display_name to User model
        },
        "datePublished": blog_post.published_at&.iso8601,
        "dateModified": blog_post.updated_at.iso8601,
        "wordCount": blog_post.word_count,
        "url": public_blog_post_url(blog_post),
        "mainEntityOfPage": {
          "@type": "WebPage",
          "@id": public_blog_post_url(blog_post)
        },
        "publisher": {
          "@type": "Organization",
          "name": "Devvme App"
        }
      }

      content_tag :script, schema.to_json.html_safe, type: "application/ld+json"
    end
  end

  def canonical_url(url)
    content_for :canonical, tag.link(rel: "canonical", href: url)
  end

  # Generate public profile URL helper method
  def public_profile_url(username, options = {})
    if options[:full_url]
      "#{request.protocol}#{request.host_with_port}/#{username}"
    else
      public_profile_path(username: username)
    end
  end
end
