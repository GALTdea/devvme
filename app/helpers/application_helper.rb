module ApplicationHelper
  require "redcarpet"
  require "rouge"
  require "rouge/plugins/redcarpet"

  # Markdown renderer with syntax highlighting
  class CustomHTMLRenderer < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet

    def initialize(options = {})
      super(options.merge(
        filter_html: true,
        no_images: false,
        no_links: false,
        no_styles: true,
        escape_html: false,
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

    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,
      no_images: true,
      no_links: true,
      no_styles: true,
      escape_html: true
    )

    markdown_processor = Redcarpet::Markdown.new(renderer,
      autolink: false,
      tables: false,
      fenced_code_blocks: false,
      strikethrough: false
    )

    markdown_processor.render(text).html_safe
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
end
