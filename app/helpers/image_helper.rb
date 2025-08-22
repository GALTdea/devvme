module ImageHelper
  # Optimized image tag with lazy loading and responsive sizing
  def optimized_image_tag(source, options = {})
    # Extract lazy loading preference
    lazy_load = options.delete(:lazy) { true }

    # Add loading attribute for lazy loading
    if lazy_load
      options[:loading] = "lazy"
      options[:decoding] = "async"
    end

    # Add srcset for responsive images if Active Storage attachment
    if source.respond_to?(:variant) && source.attached?
      options = add_responsive_srcset(source, options)
    end

    # Default alt text for accessibility
    options[:alt] ||= "Image"

    # Add default classes for better styling
    existing_classes = options[:class] || ""
    options[:class] = "#{existing_classes} transition-opacity duration-300".strip

    image_tag(source, options)
  end

  # Avatar image with optimized loading
  def avatar_image_tag(user, options = {}, size: :medium)
    case size
    when :thumbnail, :small
      image_source = user.avatar.attached? ? user.avatar_thumbnail : nil
      default_size = "w-12 h-12"
    when :medium
      image_source = user.avatar.attached? ? user.avatar_medium : nil
      default_size = "w-40 h-40"
    when :large
      image_source = user.avatar.attached? ? user.avatar : nil
      default_size = "w-64 h-64"
    else
      image_source = user.avatar.attached? ? user.avatar_medium : nil
      default_size = "w-40 h-40"
    end

    # Add default avatar classes
    options[:class] = "#{options[:class]} #{default_size} rounded-2xl object-cover".strip
    options[:alt] ||= "#{user.display_name}'s avatar"

    if image_source
      optimized_image_tag(image_source, options)
    else
      # Generate default avatar
      content_tag :div, class: "#{default_size} rounded-2xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center #{options[:class]}" do
        svg_tag("user-icon", size: size == :thumbnail ? "w-6 h-6" : "w-20 h-20")
      end
    end
  end

  # Project thumbnail with lazy loading
  def project_thumbnail_tag(project, options = {})
    options[:alt] ||= "#{project.title} thumbnail"
    options[:class] = "#{options[:class]} w-full h-full object-cover".strip

    if project.thumbnail.attached?
      optimized_image_tag(project.thumbnail, options)
    else
      # Default project thumbnail
      content_tag :div, class: "w-full h-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center" do
        svg_tag("folder-icon", "w-16 h-16")
      end
    end
  end

  # Blog post featured image
  def blog_featured_image_tag(blog_post, options = {})
    return unless blog_post.featured_image.attached?

    options[:alt] ||= blog_post.title
    options[:class] = "#{options[:class]} w-full object-cover".strip

    optimized_image_tag(blog_post.featured_image, options)
  end

  private

  # Add responsive srcset for Active Storage variants
  def add_responsive_srcset(attachment, options)
    return options unless attachment.image?

    # Generate different sizes for srcset
    variants = {
      "320w" => attachment.variant(resize_to_limit: [320, nil]),
      "640w" => attachment.variant(resize_to_limit: [640, nil]),
      "768w" => attachment.variant(resize_to_limit: [768, nil]),
      "1024w" => attachment.variant(resize_to_limit: [1024, nil]),
      "1280w" => attachment.variant(resize_to_limit: [1280, nil])
    }

    # Build srcset string
    srcset_urls = variants.map do |size, variant|
      "#{rails_blob_url(variant)} #{size}"
    end

    options[:srcset] = srcset_urls.join(", ")
    options[:sizes] ||= "(max-width: 320px) 280px, (max-width: 640px) 600px, (max-width: 768px) 728px, (max-width: 1024px) 984px, 1240px"

    options
  rescue ActiveStorage::InvariableError
    # Return original options if variant generation fails
    options
  end

  # Helper to generate SVG icons
  def svg_tag(icon_name, css_class = "w-6 h-6 text-white")
    case icon_name
    when "user-icon"
      content_tag :svg, class: css_class, fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
        content_tag :path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "1.5", d: "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
      end
    when "folder-icon"
      content_tag :svg, class: css_class, fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
        content_tag :path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "1.5", d: "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
      end
    else
      ""
    end
  end
end
