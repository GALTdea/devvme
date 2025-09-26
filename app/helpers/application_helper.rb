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

    # Use a more memory-efficient approach
    toc_html = String.new
    toc_html << '<nav class="table-of-contents">'
    toc_html << '<h3 class="toc-title">Table of Contents</h3>'
    toc_html << '<ul class="toc-list">'

    # Process headers line by line to avoid creating large intermediate arrays
    text.each_line do |line|
      if line.match(/^(\#{1,6})\s+(.+)$/)
        level = $1.length
        title = $2.strip
        anchor = title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")

        toc_html << '<li class="toc-level-' << level.to_s << '">'
        toc_html << '<a href="#' << anchor << '" class="toc-link">' << ERB::Util.html_escape(title) << "</a>"
        toc_html << "</li>"
      end
    end

    toc_html << "</ul></nav>"

    # Return empty string if no headers found
    toc_html == '<nav class="table-of-contents"><h3 class="toc-title">Table of Contents</h3><ul class="toc-list"></ul></nav>' ? "" : toc_html.html_safe
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

  # Enhanced Open Graph tags for better social sharing
  def enhanced_open_graph_tags(options = {})
    tags = []

    # Basic Open Graph tags
    tags << tag.meta(property: "og:type", content: options[:type] || "website")
    tags << tag.meta(property: "og:site_name", content: "Devvme App")
    tags << tag.meta(property: "og:locale", content: "en_US")

    # Title
    if options[:title]
      tags << tag.meta(property: "og:title", content: options[:title])
    end

    # Description
    if options[:description]
      tags << tag.meta(property: "og:description", content: options[:description])
    end

    # URL
    if options[:url]
      tags << tag.meta(property: "og:url", content: options[:url])
    end

    # Image with enhanced properties
    if options[:image]
      tags << tag.meta(property: "og:image", content: options[:image])
      # Use PNG for social images for better Twitter compatibility
      image_type = options[:image].include?("/social/") ? "image/png" : "image/jpeg"
      tags << tag.meta(property: "og:image:type", content: image_type)
      tags << tag.meta(property: "og:image:width", content: "1200")
      tags << tag.meta(property: "og:image:height", content: "630")
      tags << tag.meta(property: "og:image:alt", content: options[:image_alt] || options[:title] || "Devvme App")
    end

    # Twitter Card specific tags
    tags << tag.meta(name: "twitter:card", content: "summary_large_image")
    tags << tag.meta(name: "twitter:site", content: "@devvme_app")
    tags << tag.meta(name: "twitter:creator", content: options[:twitter_creator] || "@devvme_app")

    if options[:title]
      tags << tag.meta(name: "twitter:title", content: options[:title])
    end

    if options[:description]
      tags << tag.meta(name: "twitter:description", content: options[:description])
    end

    if options[:image]
      tags << tag.meta(name: "twitter:image", content: options[:image])
      tags << tag.meta(name: "twitter:image:alt", content: options[:image_alt] || options[:title] || "Devvme App")
    end

    # LinkedIn specific tags
    if options[:title]
      tags << tag.meta(property: "linkedin:title", content: options[:title])
    end

    if options[:description]
      tags << tag.meta(property: "linkedin:description", content: options[:description])
    end

    # Facebook specific tags for better rendering
    tags << tag.meta(property: "fb:app_id", content: Rails.application.credentials.dig(:facebook, :app_id) || ENV["FACEBOOK_APP_ID"]) if Rails.application.credentials.dig(:facebook, :app_id) || ENV["FACEBOOK_APP_ID"]

    content_for :social_meta, safe_join(tags, "\n")
  end

  # Generate social sharing URLs
  def social_sharing_url(platform, url, text = "", hashtags = "")
    encoded_url = CGI.escape(url)
    encoded_text = CGI.escape(text)
    encoded_hashtags = CGI.escape(hashtags)

    case platform.to_sym
    when :facebook
      "https://www.facebook.com/sharer/sharer.php?u=#{encoded_url}"
    when :twitter
      base_url = "https://twitter.com/intent/tweet?url=#{encoded_url}"
      base_url += "&text=#{encoded_text}" if text.present?
      base_url += "&hashtags=#{encoded_hashtags}" if hashtags.present?
      base_url
    when :linkedin
      "https://www.linkedin.com/sharing/share-offsite/?url=#{encoded_url}"
    when :reddit
      base_url = "https://reddit.com/submit?url=#{encoded_url}"
      base_url += "&title=#{encoded_text}" if text.present?
      base_url
    when :whatsapp
      "https://wa.me/?text=#{encoded_text}%20#{encoded_url}"
    when :telegram
      base_url = "https://t.me/share/url?url=#{encoded_url}"
      base_url += "&text=#{encoded_text}" if text.present?
      base_url
    when :email
      subject = "Check out this profile: #{text}"
      body = "I thought you might be interested in this developer profile:\n\n#{text}\n#{url}"
      "mailto:?subject=#{CGI.escape(subject)}&body=#{CGI.escape(body)}"
    else
      url
    end
  end

  # Add structured data for profiles
  def profile_structured_data(user)
    schema = {
      "@context": "https://schema.org",
      "@type": "Person",
      "name": user.display_name,
      "alternateName": "@#{user.username}",
      "url": request.original_url,
      "jobTitle": user.job_title,
      "worksFor": {
        "@type": "Organization",
        "name": "Devvme App"
      }
    }

    # Add image if avatar exists
    if user.avatar.attached?
      schema[:image] = {
        "@type": "ImageObject",
        "url": rails_blob_url(user.avatar),
        "width": "400",
        "height": "400"
      }
    end

    # Add description
    schema[:description] = user.bio.presence || "Developer on Devvme App"

    # Add location
    schema[:address] = user.location if user.location.present?

    # Add social links
    same_as = []
    same_as << user.github_url if user.github_url.present?
    same_as << user.linkedin_url if user.linkedin_url.present?
    same_as << user.website_url if user.website_url.present?
    same_as << user.twitter_url if user.twitter_url.present?
    schema[:sameAs] = same_as if same_as.any?

    # Add works/projects
    if user.projects.published.any?
      schema[:hasCreatedWork] = user.projects.published.limit(5).map do |project|
        {
          "@type": "CreativeWork",
          "name": project.title,
          "description": project.description,
          "url": project.demo_url,
          "dateCreated": project.created_at.iso8601
        }
      end
    end

    content_tag :script, schema.to_json.html_safe, type: "application/ld+json"
  end

  # Project Permission Helpers
  # These methods check if the current user can perform actions on projects

  def can_edit_project?(project)
    return false unless user_signed_in?
    return false if project.nil?
    project.user == current_user || current_user.can_access_admin?
  end

  def can_delete_project?(project)
    return false unless user_signed_in?
    return false if project.nil?
    project.user == current_user || current_user.can_access_admin?
  end

  def can_view_project?(project)
    return false if project.nil?
    # Anyone can view published projects, or owners/admins can view any project
    project.published? || (user_signed_in? && can_edit_project?(project))
  end

  def can_manage_project?(project)
    # Alias for can_edit_project? for semantic clarity
    can_edit_project?(project)
  end

  # Admin Permission Helpers
  def is_admin?
    user_signed_in? && current_user.can_access_admin?
  end

  def is_super_admin?
    user_signed_in? && current_user.super_admin?
  end

  def can_manage_users?
    user_signed_in? && current_user.can_manage_users?
  end

  # Registration control helper
  def registration_enabled?
    !Rails.env.production? || ENV["DISABLE_REGISTRATION"].blank?
  end
end
