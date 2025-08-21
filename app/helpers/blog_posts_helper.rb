module BlogPostsHelper
  # Status badge for blog posts
  def blog_post_status_badge(blog_post)
    if blog_post.published?
      content_tag :span, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200" do
        concat(content_tag(:svg, class: "w-3 h-3 mr-1", fill: "currentColor", viewBox: "0 0 20 20") do
          content_tag(:path, "", fill_rule: "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z", clip_rule: "evenodd")
        end)
        concat("Published")
      end
    else
      content_tag :span, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200" do
        concat(content_tag(:svg, class: "w-3 h-3 mr-1", fill: "currentColor", viewBox: "0 0 20 20") do
          content_tag(:path, "", fill_rule: "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z", clip_rule: "evenodd")
        end)
        concat("Draft")
      end
    end
  end

  # Publication date or last updated
  def blog_post_date_info(blog_post)
    if blog_post.published?
      "Published #{time_ago_in_words(blog_post.published_at)} ago"
    else
      "Updated #{time_ago_in_words(blog_post.updated_at)} ago"
    end
  end

  # Reading stats
  def blog_post_reading_stats(blog_post)
    content_tag :div, class: "flex items-center text-xs text-gray-500 dark:text-gray-400 space-x-4" do
      concat(content_tag(:span, class: "flex items-center") do
        concat(content_tag(:svg, class: "w-4 h-4 mr-1", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          content_tag(:path, "", stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z")
        end)
        concat("#{blog_post.reading_time} min read")
      end)

      concat(content_tag(:span, class: "flex items-center") do
        concat(content_tag(:svg, class: "w-4 h-4 mr-1", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          content_tag(:path, "", stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z")
        end)
        concat(pluralize(blog_post.word_count, "word"))
      end)
    end
  end

  # Status filter link with count
  def status_filter_link(status, count, current_status)
    active = (current_status == status) || (status.nil? && current_status.blank?)
    css_classes = if active
      "px-4 py-2 text-sm font-medium bg-blue-600 text-white"
    else
      "px-4 py-2 text-sm font-medium bg-white text-gray-900 hover:bg-gray-50 dark:bg-gray-800 dark:text-white dark:hover:bg-gray-700"
    end

    case status
    when nil
      css_classes += " border-r border-gray-200 dark:border-gray-600 rounded-l-lg"
      link_to "All (#{count})", blog_posts_path, class: "#{css_classes} transition-colors"
    when "published"
      css_classes += " border-r border-gray-200 dark:border-gray-600"
      link_to "Published (#{count})", blog_posts_path(status: "published"), class: "#{css_classes} transition-colors"
    when "draft"
      css_classes += " rounded-r-lg"
      link_to "Drafts (#{count})", blog_posts_path(status: "draft"), class: "#{css_classes} transition-colors"
    end
  end

  # Truncated excerpt with fallback
  def blog_post_excerpt(blog_post, length = 150)
    if blog_post.excerpt.present?
      truncate(blog_post.excerpt, length: length)
    else
      # Generate excerpt from content
      plain_text = strip_tags(blog_post.content.gsub(/[#*`_\[\]()!]/, ""))
                                             .gsub(/\n+/, " ")
                                             .strip
      truncate(plain_text, length: length)
    end
  end

  # Quick action buttons for blog post row
  def blog_post_actions(blog_post)
    content_tag :div, class: "flex items-center space-x-2 ml-4" do
      concat(link_to(blog_post,
        class: "p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors",
        title: "View") do
        content_tag(:svg, class: "w-5 h-5", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          concat(content_tag(:path, "", stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M15 12a3 3 0 11-6 0 3 3 0 016 0z"))
          concat(content_tag(:path, "", stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"))
        end
      end)

      concat(link_to(edit_blog_post_path(blog_post),
        class: "p-2 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors",
        title: "Edit") do
        content_tag(:svg, class: "w-5 h-5", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          content_tag(:path, "", stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z")
        end
      end)

      concat(link_to(blog_post,
        method: :delete,
        data: {
          confirm: "Are you sure you want to delete '#{blog_post.title}'? This action cannot be undone.",
          turbo_method: :delete
        },
        class: "p-2 text-gray-400 hover:text-red-600 dark:hover:text-red-400 transition-colors",
        title: "Delete") do
        content_tag(:svg, class: "w-5 h-5", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          content_tag(:path, "", stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16")
        end
      end)
    end
  end
end
