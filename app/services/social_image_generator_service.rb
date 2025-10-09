class SocialImageGeneratorService
  include Rails.application.routes.url_helpers
  require "base64"

  def initialize(user)
    @user = user
  end

  def generate_profile_image
    # Generate a branded social media image for the user's profile
    # Always create the branded template for consistency across all users
    create_branded_template_image
  end

  private

  def create_branded_avatar_image
    # For now, we'll return the user's avatar URL
    # In production, you'd create a branded version using ImageMagick or similar
    host_options = Rails.application.config.action_mailer.default_url_options
    rails_blob_url(@user.avatar, host: "#{host_options[:host]}:#{host_options[:port]}")
  end

  def create_branded_template_image
    # Create a branded template image for all users
    create_branded_svg_image
  end

  def create_branded_svg_image
    # Create a simple branded image using SVG and save as file
    # This creates a gradient background with the user's name and branding

    name = @user.display_name
    username = @user.username
    skills = @user.skills&.first(3) || []
    job_title = @user.job_title
    bio = @user.bio
    location = @user.location

    svg_content = <<~SVG
      <svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#f0fdf4;stop-opacity:1" />
            <stop offset="50%" style="stop-color:#dcfce7;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#bbf7d0;stop-opacity:1" />
          </linearGradient>
          <linearGradient id="card" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#ffffff;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#ffffff;stop-opacity:1" />
          </linearGradient>
          <linearGradient id="badge" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#a855f7;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#7c3aed;stop-opacity:1" />
          </linearGradient>
          <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
            <feDropShadow dx="0" dy="4" stdDeviation="8" flood-color="#000000" flood-opacity="0.05"/>
          </filter>
        </defs>

        <!-- Background -->
        <rect width="1200" height="630" fill="url(#bg)"/>

        <!-- Background pattern -->
        <pattern id="dots" x="0" y="0" width="60" height="60" patternUnits="userSpaceOnUse">
          <circle cx="30" cy="30" r="1" fill="#86efac" opacity="0.2"/>
        </pattern>
        <rect width="1200" height="630" fill="url(#dots)"/>

        <!-- Main card with subtle shadow -->
        <rect x="100" y="70" width="1000" height="490" rx="24" fill="url(#card)" filter="url(#shadow)" stroke="rgba(226,232,240,0.5)" stroke-width="1"/>

        <!-- Avatar -->
        #{avatar_svg}

        <!-- Badge with improved styling -->
        <rect x="340" y="110" width="200" height="36" rx="18" fill="url(#badge)"/>
        <text x="440" y="134" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="14" font-weight="700">DEVELOPER PROFILE</text>

        <!-- Name with better contrast -->
        <text x="340" y="210" fill="#1F2937" font-family="Arial, sans-serif" font-size="48" font-weight="800">#{name}</text>

        <!-- Username with better styling -->
        <text x="340" y="250" fill="#6B7280" font-family="Arial, sans-serif" font-size="24" font-weight="600">@#{username}</text>

        <!-- Tagline with better visibility -->
        <text x="340" y="290" fill="#374151" font-family="Arial, sans-serif" font-size="20" font-weight="600">A developer profile worth sharing</text>

        <!-- Skills -->
        #{skills_svg(skills)}

        <!-- Social Links -->
        #{social_links_svg}

        <!-- Branding with better visibility -->
        <text x="1080" y="570" text-anchor="end" fill="#334155" font-family="Arial, sans-serif" font-size="18" font-weight="700">devv.me</text>
      </svg>
    SVG

    # Save SVG to file first
    svg_filename = "social_#{@user.id}_#{Time.current.to_i}.svg"
    svg_path = Rails.root.join("tmp", svg_filename)
    File.write(svg_path, svg_content)

    # Convert SVG to PNG for better social media compatibility
    png_filename = "social_#{@user.id}_#{Time.current.to_i}.png"
    png_path = Rails.root.join("tmp", png_filename)

        # Use libvips to convert SVG to PNG
        # Use vips command for better SVG to PNG conversion (Hatchbox recommended)
        # libvips preserves SVG colors and gradients more accurately
        Rails.logger.info "Converting SVG to PNG with libvips"
        conversion_result = system("vips copy #{svg_path} #{png_path}")
        Rails.logger.info "libvips conversion result: #{conversion_result}"

    # Debug: Check if conversion worked
    if File.exist?(png_path)
      file_info = `file #{png_path}`.strip
      Rails.logger.info "libvips conversion result: #{file_info}"

          # If it's still grayscale or 1-bit, try alternative approach
          if file_info.include?("1-bit") || file_info.include?("grayscale")
            Rails.logger.info "Retrying with different libvips options for color"
            system("vips resize #{svg_path} #{png_path} 1.0")
          end

      # Clean up the SVG file only if PNG conversion succeeded
      File.delete(svg_path) if File.exist?(svg_path)
      png_path
    else
      # Conversion failed, return SVG path and keep the SVG file
      Rails.logger.warn "libvips conversion failed, returning SVG file"
      svg_path
    end
  end

      def avatar_svg
        if @user.avatar.attached?
          # Convert avatar to base64 for embedding in SVG
          begin
            avatar_data = @user.avatar.download
            avatar_base64 = Base64.strict_encode64(avatar_data)
            avatar_mime_type = @user.avatar.content_type || "image/jpeg"

            Rails.logger.info "Processing avatar for user #{@user.id}: #{avatar_mime_type}, #{avatar_data.length} bytes"

            <<~SVG
              <defs>
                <clipPath id="avatar-clip">
                  <rect x="140" y="110" width="160" height="160" rx="20"/>
                </clipPath>
              </defs>
              <rect x="140" y="110" width="160" height="160" rx="20" fill="#f0fdf4"/>
              <image x="140" y="110" width="160" height="160" href="data:#{avatar_mime_type};base64,#{avatar_base64}" clip-path="url(#avatar-clip)"/>
              <rect x="140" y="110" width="160" height="160" rx="20" fill="none" stroke="#a855f7" stroke-width="3"/>
            SVG
          rescue => e
            Rails.logger.error "Failed to process avatar for user #{@user.id}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            # Fall back to placeholder if avatar processing fails
            default_avatar_svg
          end
        else
          # Default avatar placeholder
          default_avatar_svg
        end
      end

      def default_avatar_svg
        <<~SVG
          <defs>
            <linearGradient id="avatar-bg" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style="stop-color:#a855f7;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#7c3aed;stop-opacity:1" />
            </linearGradient>
          </defs>
          <rect x="140" y="110" width="160" height="160" rx="20" fill="url(#avatar-bg)"/>
          <circle cx="220" cy="190" r="50" fill="rgba(255,255,255,0.2)"/>
          <text x="220" y="210" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="60" font-weight="bold">👨‍💻</text>
          <rect x="140" y="110" width="160" height="160" rx="20" fill="none" stroke="#ffffff" stroke-width="3"/>
        SVG
      end

  def skills_svg(skills)
    # If no skills, show fallback developer information
    if skills.empty?
      y_pos = 320
      fallback_html = ""

      # Show job title if available
      if @user.job_title.present?
        fallback_html += "<text x=\"360\" y=\"#{y_pos}\" fill=\"#374151\" font-family=\"Arial, sans-serif\" font-size=\"18\" font-weight=\"600\">#{@user.job_title}</text>"
        y_pos += 30
      end

      # Show bio if available (truncated)
      if @user.bio.present?
        bio_text = @user.bio.length > 60 ? @user.bio[0..57] + "..." : @user.bio
        fallback_html += "<text x=\"360\" y=\"#{y_pos}\" fill=\"#6B7280\" font-family=\"Arial, sans-serif\" font-size=\"16\" font-weight=\"400\">#{bio_text}</text>"
        y_pos += 25
      end

      # Show location if available
      if @user.location.present?
        fallback_html += "<text x=\"360\" y=\"#{y_pos}\" fill=\"#9CA3AF\" font-family=\"Arial, sans-serif\" font-size=\"14\" font-weight=\"500\">📍 #{@user.location}</text>"
        y_pos += 25
      end

      # If still no content, show a generic message
      if fallback_html.empty?
        fallback_html = "<text x=\"360\" y=\"#{y_pos}\" fill=\"#9CA3AF\" font-family=\"Arial, sans-serif\" font-size=\"16\" font-weight=\"500\">Full-stack Developer</text>"
      end

      return fallback_html
    end

    y_pos = 320
    skills_html = ""

    skills.each_with_index do |skill, index|
      x_pos = 360 + (index * 130)
      skills_html += <<~SVG
        <rect x="#{x_pos}" y="#{y_pos}" width="110" height="28" rx="14" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.3)" stroke-width="1"/>
        <text x="#{x_pos + 55}" y="#{y_pos + 18}" text-anchor="middle" fill="#a855f7" font-family="Arial, sans-serif" font-size="13" font-weight="600">#{skill}</text>
      SVG
    end

    skills_html
  end

  def social_links_svg
    links_html = ""
    x_pos = 360
    y_pos = 450

    # GitHub link
    if @user.github_url.present?
      links_html += "<text x=\"#{x_pos}\" y=\"#{y_pos}\" fill=\"#6B7280\" font-family=\"Arial, sans-serif\" font-size=\"14\" font-weight=\"500\">🔗 GitHub</text>"
      x_pos += 120
    end

    # LinkedIn link
    if @user.linkedin_url.present?
      links_html += "<text x=\"#{x_pos}\" y=\"#{y_pos}\" fill=\"#6B7280\" font-family=\"Arial, sans-serif\" font-size=\"14\" font-weight=\"500\">💼 LinkedIn</text>"
      x_pos += 120
    end

    # Website link
    if @user.website_url.present?
      links_html += "<text x=\"#{x_pos}\" y=\"#{y_pos}\" fill=\"#6B7280\" font-family=\"Arial, sans-serif\" font-size=\"14\" font-weight=\"500\">🌐 Website</text>"
    end

    links_html
  end
end
