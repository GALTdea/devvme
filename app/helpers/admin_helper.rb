module AdminHelper
  # Admin navigation helper methods

  def admin_nav_link(text, path, options = {})
    default_classes = "px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200"

    if current_page?(path) || (options[:active_when] && current_page?(options[:active_when]))
      active_classes = "bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-200"
      css_classes = "#{default_classes} #{active_classes}"
    else
      inactive_classes = "text-secondary-600 hover:text-secondary-900 dark:text-secondary-300 dark:hover:text-white hover:bg-secondary-100 dark:hover:bg-secondary-700"
      css_classes = "#{default_classes} #{inactive_classes}"
    end

    link_to text, path, class: css_classes
  end

  def admin_breadcrumbs(*crumbs)
    return unless crumbs.any?

    content_tag :nav, class: "flex mb-4", "aria-label": "Breadcrumb" do
      content_tag :ol, class: "inline-flex items-center space-x-1 md:space-x-3" do
        crumbs.map.with_index do |crumb, index|
          is_last = index == crumbs.length - 1

          content_tag :li, class: "inline-flex items-center" do
            content = ""

            # Add separator for non-first items
            unless index == 0
              content += content_tag(:svg, class: "w-6 h-6 text-secondary-400", fill: "currentColor", viewBox: "0 0 20 20", xmlns: "http://www.w3.org/2000/svg") do
                content_tag(:path, "", "fill-rule": "evenodd", d: "M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z", "clip-rule": "evenodd")
              end
            end

            # Add the crumb content
            if is_last
              # Last crumb is not a link
              content += content_tag(:span, crumb[:text], class: "ml-1 text-sm font-medium text-secondary-500 dark:text-secondary-400 md:ml-2")
            else
              # Other crumbs are links
              content += link_to(crumb[:text], crumb[:path], class: "ml-1 text-sm font-medium text-secondary-700 hover:text-primary-600 dark:text-secondary-300 dark:hover:text-primary-400 md:ml-2")
            end

            content.html_safe
          end
        end.join.html_safe
      end
    end
  end

  def admin_page_header(title, subtitle = nil, &block)
    content_tag :div, class: "bg-white dark:bg-secondary-800 shadow" do
      content_tag :div, class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" do
        content_tag :div, class: "py-6" do
          content_tag :div, class: "flex items-center justify-between" do
            header_content = content_tag :div do
              title_content = content_tag(:h1, title, class: "text-2xl font-bold text-secondary-900 dark:text-white")
              subtitle_content = subtitle ? content_tag(:p, subtitle, class: "mt-1 text-sm text-secondary-600 dark:text-secondary-400") : ""
              title_content + subtitle_content
            end

            actions_content = block_given? ? content_tag(:div, class: "flex items-center space-x-4", &block) : ""

            header_content + actions_content
          end
        end
      end
    end
  end

  def admin_section_nav(sections, current_section = nil)
    content_tag :div, class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4" do
      content_tag :nav, class: "flex space-x-4", "aria-label": "Section Navigation" do
        sections.map do |section|
          is_current = current_section == section[:key] || current_page?(section[:path])
          admin_nav_link(section[:text], section[:path], active_when: section[:active_when])
        end.join.html_safe
      end
    end
  end

  # Permission helpers for admin interface
  def can_create_users?
    current_user&.super_admin?
  end

  def can_manage_users?
    current_user&.can_manage_users?
  end

  def can_delete_users?
    current_user&.super_admin?
  end

  def can_manage_roles?
    current_user&.super_admin?
  end

  def can_bulk_operations?
    current_user&.super_admin?
  end

  def can_access_admin?
    current_user&.can_access_admin?
  end

  # User status helpers
  def user_status_badge(user)
    case user.account_status
    when "pending_activation"
      content_tag :span, "Pending Activation", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
    when "invited"
      content_tag :span, "Invited", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200"
    when "active"
      content_tag :span, "Active", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
    when "suspended"
      content_tag :span, "Suspended", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
    when "deactivated"
      content_tag :span, "Deactivated", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"
    else
      content_tag :span, user.account_status.humanize, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"
    end
  end

  def user_role_badge(user)
    case user.role
    when "super_admin"
      content_tag :span, "Super Admin", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
    when "admin"
      content_tag :span, "Admin", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
    else
      content_tag :span, "User", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"
    end
  end

  # Invitation status helpers
  def invitation_status_text(user)
    return unless user.invited?

    if user.invitation_expired?
      "Expired"
    elsif user.invitation_pending?
      days_remaining = ((user.invitation_sent_at + 30.days - Time.current) / 1.day).to_i
      "Pending (expires in #{pluralize(days_remaining, 'day')})"
    else
      "Unknown"
    end
  end

  def invitation_status_class(user)
    return unless user.invited?

    if user.invitation_expired?
      "text-red-600 dark:text-red-400"
    elsif user.invitation_pending?
      "text-amber-600 dark:text-amber-400"
    else
      "text-gray-600 dark:text-gray-400"
    end
  end
end
