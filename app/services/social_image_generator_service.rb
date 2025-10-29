class SocialImageGeneratorService
  include Rails.application.routes.url_helpers
  require "base64"

  def initialize(user, card_type = "auto")
    @user = user
    @card_type = card_type
  end

  def generate_profile_image(version = nil)
    # Generate a branded social media image for the user's profile
    # Always create the branded template for consistency across all users
    create_branded_template_image(version)
  end

  private

  def create_branded_avatar_image
    # For now, we'll return the user's avatar URL
    # In production, you'd create a branded version using ImageMagick or similar
    host_options = Rails.application.config.action_mailer.default_url_options
    rails_blob_url(@user.avatar, host: "#{host_options[:host]}:#{host_options[:port]}")
  end

  def create_branded_template_image(version = nil)
    # Create a single dynamic social card with content based on card_type parameter
    generate_dynamic_social_card(version)
  end

  def generate_dynamic_social_card(version = nil)
    # Generate a single social card with dynamic content based on card_type parameter
    # Always use the same filename pattern: social_{user_id}_{version}.png

    # Check if we already have a cached image for this version
    if version.present?
      cached_image = get_cached_image_for_version(version)
      return cached_image if cached_image && File.exist?(cached_image)
    end

    name = @user.display_name
    username = @user.username
    skills = @user.skills&.first(4) || []  # Show only 3-4 skills to avoid clutter
    job_title = @user.job_title
    bio = truncate_bio(@user.bio)  # Truncate bio intelligently
    location = @user.location

    # Determine the effective card type (handle auto mode)
    effective_card_type = determine_effective_card_type

    # Generate dynamic SVG content based on card type
    svg_content = generate_dynamic_svg_content(name, username, skills, job_title, bio, location, effective_card_type)

    # Generate version-specific filenames (always use standard pattern)
    version_suffix = version.present? ? "_#{version}" : "_#{Time.current.to_i}"
    svg_filename = "social_#{@user.id}#{version_suffix}.svg"
    svg_path = Rails.root.join("tmp", svg_filename)
    File.write(svg_path, svg_content)

    # Convert SVG to PNG for better social media compatibility
    png_filename = "social_#{@user.id}#{version_suffix}.png"
    png_path = Rails.root.join("tmp", png_filename)

    # Try libvips first (if available), then fall back to ImageMagick
    if system("which vips > /dev/null 2>&1")
      # Use libvips for conversion (faster and better quality)
      system("vips copy #{svg_path} #{png_path}")
    else
      # Fall back to ImageMagick
      system("convert #{svg_path} #{png_path}")
    end

    # Clean up the SVG file
    File.delete(svg_path) if File.exist?(svg_path)

    Rails.logger.info "Generated dynamic social card for #{@user.username} (#{effective_card_type}): #{png_filename}"
    png_path
  end

  def determine_effective_card_type
    # Determine the effective card type based on the requested type and user status
    case @card_type
    when "hire", "open_to_work"
      "hire"
    when "professional"
      "professional"
    when "auto"
      # Auto mode: show hire card if user is open for work, otherwise professional
      @user.open_for_work? ? "hire" : "professional"
    else
      # Default to professional card
      "professional"
    end
  end

  def generate_dynamic_svg_content(name, username, skills, job_title, bio, location, card_type)
    # Generate SVG content with dynamic styling based on card_type
    case card_type
    when "hire"
      generate_hire_svg_content(name, username, skills, job_title, bio, location)
    when "professional"
      create_professional_svg_content(name, username, skills, job_title, bio, location)
    else
      create_professional_svg_content(name, username, skills, job_title, bio, location)
    end
  end

  def generate_hire_svg_content(name, username, skills, job_title, bio, location)
    # Generate hire/open to work card SVG content with improved styling
    <<~SVG
      <svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <!-- Enhanced Hire Card Gradient Background -->
          <linearGradient id="hire-bg" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#0a1628;stop-opacity:1" />
            <stop offset="35%" style="stop-color:#0f172a;stop-opacity:1" />
            <stop offset="65%" style="stop-color:#1e293b;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#334155;stop-opacity:1" />
          </linearGradient>

          <!-- Enhanced gradient accents -->
          <linearGradient id="hire-accent" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" style="stop-color:#22c55e;stop-opacity:0.1" />
            <stop offset="50%" style="stop-color:#06b6d4;stop-opacity:0.15" />
            <stop offset="100%" style="stop-color:#22c55e;stop-opacity:0.1" />
          </linearGradient>

          <!-- Hire pattern overlay - more subtle -->
          <pattern id="hire-dots" x="0" y="0" width="60" height="60" patternUnits="userSpaceOnUse">
            <circle cx="30" cy="30" r="1.5" fill="#22c55e" opacity="0.15"/>
          </pattern>

          <!-- Shadow for depth -->
          <filter id="hire-shadow" x="-50%" y="-50%" width="200%" height="200%">
            <feDropShadow dx="0" dy="8" stdDeviation="16" flood-color="#000000" flood-opacity="0.35"/>
          </filter>
        </defs>

        <!-- Enhanced Hire Background -->
        <rect width="1200" height="630" fill="url(#hire-bg)"/>
        <rect width="1200" height="100" y="0" fill="url(#hire-accent)"/>
        <rect width="1200" height="630" fill="url(#hire-dots)"/>

        <!-- Left Side: Avatar with shadow -->
        <g filter="url(#hire-shadow)">
          #{hire_avatar_svg}
        </g>

        <!-- Right Side: Content Area -->
        <g>
          <!-- Name with larger font -->
          <text x="380" y="145" fill="#ffffff" font-family="Arial, sans-serif" font-size="58" font-weight="900" letter-spacing="-1">#{name}</text>

          <!-- Job Title -->
          #{hire_job_title_svg}

          <!-- Headline -->
          #{hire_headline_svg}

          <!-- Bio/Location Section with improved styling -->
          #{hire_info_section}

          <!-- Skills -->
          #{hire_skills_svg(skills)}

          <!-- Footer -->
          #{hire_footer_svg}
        </g>
      </svg>
    SVG
  end

  # Hire card helper methods
  def hire_avatar_svg
    avatar_svg_content = ""

    if @user.avatar.attached?
      # Convert avatar to base64 for embedding in SVG
      begin
        avatar_data = @user.avatar.download
        avatar_mime_type = @user.avatar.content_type
        avatar_base64 = Base64.encode64(avatar_data).gsub(/\n/, "")

        avatar_svg_content = <<~SVG
          <!-- Avatar with hire styling -->
          <defs>
            <clipPath id="hire-avatar-clip">
              <circle cx="190" cy="270" r="90"/>
            </clipPath>
          </defs>
          <image x="100" y="180" width="180" height="180" href="data:#{avatar_mime_type};base64,#{avatar_base64}" clip-path="url(#hire-avatar-clip)"/>
          <!-- Green border ring for hire card -->
          <circle cx="190" cy="270" r="90" fill="none" stroke="rgba(34,197,94,0.8)" stroke-width="4"/>
        SVG
      rescue => e
        Rails.logger.error "Failed to process avatar for user #{@user.id}: #{e.message}"
        avatar_svg_content = hire_default_avatar_svg_content
      end
    else
      avatar_svg_content = hire_default_avatar_svg_content
    end

    # Add the hire badge below the avatar
    avatar_svg_content + hire_badge_below_avatar_svg
  end

  def hire_default_avatar_svg_content
    <<~SVG
      <!-- Default hire avatar -->
      <circle cx="190" cy="270" r="90" fill="rgba(34,197,94,0.2)"/>
      <!-- Green border ring for hire card -->
      <circle cx="190" cy="270" r="90" fill="none" stroke="rgba(34,197,94,0.8)" stroke-width="4"/>
    SVG
  end

  def hire_default_avatar_svg
    hire_default_avatar_svg_content
  end

  def hire_badge_below_avatar_svg
    <<~SVG
      <!-- AVAILABLE FOR HIRE badge below avatar -->
      <defs>
        <linearGradient id="hire-badge-left" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#22c55e;stop-opacity:1" />
          <stop offset="100%" style="stop-color:#16a34a;stop-opacity:1" />
        </linearGradient>
      </defs>
      <rect x="55" y="380" width="270" height="45" rx="22" fill="url(#hire-badge-left)" opacity="0.95"/>
      <text x="190" y="407" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="18" font-weight="800" letter-spacing="0.6">⚡ AVAILABLE FOR HIRE</text>
    SVG
  end

  def hire_job_title_svg
    title_text = @user.job_title.presence || @user.preferred_roles.first || "Developer"

    <<~SVG
      <text x="380" y="195" fill="rgba(255,255,255,0.95)" font-family="Arial, sans-serif" font-size="32" font-weight="600">#{escape_xml(title_text)}</text>
    SVG
  end

  def hire_headline_svg
    return "" unless @user.headline.present?

    # Truncate headline if too long
    headline_text = truncate_bio(@user.headline, 60)

    <<~SVG
      <text x="380" y="225" fill="rgba(255,255,255,0.8)" font-family="Arial, sans-serif" font-size="22" font-weight="500" font-style="italic">#{escape_xml(headline_text)}</text>
    SVG
  end

  def hire_badge_svg
    # Green "AVAILABLE FOR HIRE" badge with larger font
    <<~SVG
      <defs>
        <linearGradient id="hire-badge" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#22c55e;stop-opacity:1" />
          <stop offset="100%" style="stop-color:#16a34a;stop-opacity:1" />
        </linearGradient>
      </defs>
      <rect x="380" y="225" width="320" height="50" rx="25" fill="url(#hire-badge)" opacity="0.95"/>
      <text x="540" y="260" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="20" font-weight="800" letter-spacing="0.8">⚡ AVAILABLE FOR HIRE</text>
    SVG
  end

  def hire_info_section
    # Get bio and location separately for multi-line display
    bio_text = truncate_bio(@user.bio, 70)  # Truncate to fit on card width
    location_text = @user.location.present? ? "📍 #{@user.location}" : ""

    # Calculate available width (1200 - 380 - 100 for right padding)
    available_width = 720

    # Break bio into multiple lines if needed
    bio_lines = wrap_text(bio_text, available_width, 24) if bio_text.present?
    location_lines = wrap_text(location_text, available_width, 24) if location_text.present?

    # Adjust starting position based on whether headline exists
    # Add more spacing when headline is present
    start_y = @user.headline.present? ? 265 : 280

    html = ""
    y_pos = start_y

    # Display bio on multiple lines
    if bio_lines
      bio_lines.each do |line|
        html += %(<tspan x="380" dy="#{y_pos == start_y ? '0' : '30'}">#{escape_xml(line)}</tspan>)
        y_pos += 30
      end
    end

    # Add location if available
    if location_lines
      location_lines.each do |line|
        html += %(<tspan x="380" dy="32">#{escape_xml(line)}</tspan>)
      end
    end

    <<~SVG
      <text x="380" y="#{start_y}" fill="rgba(255,255,255,0.95)" font-family="Arial, sans-serif" font-size="24" font-weight="500">#{html}</text>
    SVG
  end

  def wrap_text(text, max_width, font_size)
    # Simple word wrap algorithm - approximate character width
    chars_per_line = (max_width / (font_size * 0.6)).to_i
    words = text.split(' ')
    lines = []
    current_line = []

    words.each do |word|
      if (current_line + [word]).join(' ').length <= chars_per_line
        current_line << word
      else
        lines << current_line.join(' ') unless current_line.empty?
        current_line = [word]
      end
    end

    lines << current_line.join(' ') unless current_line.empty?
    lines
  end

  def hire_skills_svg(skills)
    return "" if skills.empty?

    y_pos = 365  # Adjusted spacing
    x_pos = 380
    html = ""

    skills.each_with_index do |skill, index|
      width = skill.length * 12 + 24  # Larger width for better readability
      html += <<~SVG
        <rect x="#{x_pos}" y="#{y_pos}" width="#{width}" height="36" rx="18" fill="rgba(34,197,94,0.2)" stroke="rgba(34,197,94,0.5)" stroke-width="1.5"/>
        <text x="#{x_pos + width/2}" y="#{y_pos + 24}" text-anchor="middle" fill="#22c55e" font-family="Arial, sans-serif" font-size="16" font-weight="600">#{skill}</text>
      SVG
      x_pos += width + 18  # More spacing between skills
    end

    html
  end

  def hire_footer_svg
    <<~SVG
      <!-- Divider line -->
      <line x1="100" y1="550" x2="1100" y2="550" stroke="rgba(34,197,94,0.3)" stroke-width="2"/>

      <!-- CTA and branding -->
      <text x="100" y="580" fill="rgba(255,255,255,0.9)" font-family="Arial, sans-serif" font-size="18" font-weight="600">👉 Get in touch at devv.me/#{@user.username}</text>
      <text x="1070" y="580" text-anchor="end" fill="rgba(255,255,255,0.95)" font-family="Arial, sans-serif" font-size="24" font-weight="900">devv.me</text>
    SVG
  end

  def create_open_to_work_svg_image(version = nil)
    # Create an open to work branded image using SVG and save as file
    # This creates a gradient background with the user's name, work status, and branding

    # Check if we already have a cached image for this version
    if version.present?
      cached_image = get_cached_image_for_version(version)
      return cached_image if cached_image && File.exist?(cached_image)
    end

    name = @user.display_name
    username = @user.username
    skills = @user.skills&.first(3) || []
    job_title = @user.job_title
    bio = @user.bio
    location = @user.location

    svg_content = <<~SVG
      <svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <!-- Gradient Hero Background -->
          <linearGradient id="hero-bg" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#10b981;stop-opacity:1" />
            <stop offset="50%" style="stop-color:#14b8a6;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#06b6d4;stop-opacity:1" />
          </linearGradient>

          <!-- Badge gradients -->
          <linearGradient id="badge" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#a855f7;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#7c3aed;stop-opacity:1" />
          </linearGradient>

          <!-- Subtle pattern overlay -->
          <pattern id="dots" x="0" y="0" width="60" height="60" patternUnits="userSpaceOnUse">
            <circle cx="30" cy="30" r="1.5" fill="#ffffff" opacity="0.15"/>
          </pattern>

          <!-- Shadow for depth -->
          <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
            <feDropShadow dx="0" dy="8" stdDeviation="16" flood-color="#000000" flood-opacity="0.2"/>
          </filter>
        </defs>

        <!-- Full Gradient Background -->
        <rect width="1200" height="630" fill="url(#hero-bg)"/>
        <rect width="1200" height="630" fill="url(#dots)"/>

        <!-- Left Side: Avatar with shadow -->
        <g filter="url(#shadow)">
        #{avatar_svg}
        </g>

        <!-- Right Side: Content Area -->
        <g>
          <!-- Name -->
          <text x="380" y="140" fill="#ffffff" font-family="Arial, sans-serif" font-size="52" font-weight="900" letter-spacing="-0.5">#{name}</text>

          <!-- Job Title -->
          #{job_title_svg}

          <!-- Available for Hire Badge -->
          #{badge_svg}

          <!-- Work Info Section -->
          #{work_info_section}

        <!-- Skills -->
          #{gradient_skills_svg(skills)}

          <!-- Footer -->
          #{footer_svg}
        </g>
      </svg>
    SVG

    # Generate version-specific filenames
    version_suffix = version.present? ? "_#{version}" : "_#{Time.current.to_i}"
    svg_filename = "social_#{@user.id}#{version_suffix}.svg"
    svg_path = Rails.root.join("tmp", svg_filename)
    File.write(svg_path, svg_content)

    # Convert SVG to PNG for better social media compatibility
    png_filename = "social_#{@user.id}#{version_suffix}.png"
    png_path = Rails.root.join("tmp", png_filename)

        # Try libvips first (if available), then fall back to ImageMagick
        Rails.logger.info "Converting SVG to PNG"

        # Check if libvips is available
        if system("which vips > /dev/null 2>&1")
          Rails.logger.info "Using libvips for conversion"
          conversion_result = system("vips copy #{svg_path} #{png_path}")
          Rails.logger.info "libvips conversion result: #{conversion_result}"
        else
          Rails.logger.info "libvips not available, using ImageMagick"
          # Use ImageMagick with proper flags for color output
          conversion_result = system("convert -background transparent -size 1200x630 -colorspace RGB -type TrueColor #{svg_path} #{png_path}")
          Rails.logger.info "ImageMagick conversion result: #{conversion_result}"
        end

    # Debug: Check if conversion worked
    if File.exist?(png_path)
      file_info = `file #{png_path}`.strip
      Rails.logger.info "Conversion result: #{file_info}"

          # If it's still grayscale or 1-bit, try alternative approach
          if file_info.include?("1-bit") || file_info.include?("grayscale")
            Rails.logger.info "Retrying with different conversion options for color"
            if system("which vips > /dev/null 2>&1")
              system("vips resize #{svg_path} #{png_path} 1.0")
            else
              system("convert -background transparent -size 1200x630 -colorspace RGB -depth 8 -type TrueColorAlpha #{svg_path} #{png_path}")
            end
          end

      # Clean up the SVG file only if PNG conversion succeeded
      File.delete(svg_path) if File.exist?(svg_path)
      png_path
    else
      # Conversion failed, return SVG path and keep the SVG file
      Rails.logger.warn "Image conversion failed, returning SVG file"
      svg_path
    end
  end

  def create_professional_svg_image(version = nil)
    # Create a professional branded image using SVG and save as file
    # This creates a clean, professional card focused on showcasing the user's work and skills

    # Check if we already have a cached image for this version
    if version.present?
      cached_image = get_cached_image_for_version(version)
      return cached_image if cached_image && File.exist?(cached_image)
    end

    name = @user.display_name
    username = @user.username
    skills = @user.skills&.first(6) || []
    job_title = @user.job_title
    bio = @user.bio
    location = @user.location

    svg_content = create_professional_svg_content(name, username, skills, job_title, bio, location)

    # Generate version-specific filenames
    version_suffix = version.present? ? "_#{version}" : "_#{Time.current.to_i}"
    svg_filename = "social_professional_#{@user.id}#{version_suffix}.svg"
    svg_path = Rails.root.join("tmp", svg_filename)
    File.write(svg_path, svg_content)

    # Convert SVG to PNG for better social media compatibility
    png_filename = "social_professional_#{@user.id}#{version_suffix}.png"
    png_path = Rails.root.join("tmp", png_filename)

    # Try libvips first (if available), then fall back to ImageMagick
    if system("which vips > /dev/null 2>&1")
      # Use libvips for conversion (faster and better quality)
      system("vips copy #{svg_path} #{png_path}")
    elsif system("which convert > /dev/null 2>&1")
      # Fall back to ImageMagick
      system("convert #{svg_path} #{png_path}")
    else
      Rails.logger.warn "Neither libvips nor ImageMagick found, keeping SVG file"
    end

    # Return PNG if conversion succeeded, otherwise return SVG
    if File.exist?(png_path) && File.size(png_path) > 0
      # Clean up SVG file
      File.delete(svg_path) if File.exist?(svg_path)
      png_path
    else
      # Conversion failed, return SVG path and keep the SVG file
      Rails.logger.warn "Image conversion failed, returning SVG file"
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

            # Left-aligned avatar for split-panel layout
            avatar_html = <<~SVG
              <defs>
                <clipPath id="avatar-clip">
                  <circle cx="190" cy="270" r="90"/>
                </clipPath>
              </defs>
              <!-- White ring for contrast -->
              <circle cx="190" cy="270" r="95" fill="white" opacity="0.3"/>
              <!-- Avatar image -->
              <image x="100" y="180" width="180" height="180" href="data:#{avatar_mime_type};base64,#{avatar_base64}" clip-path="url(#avatar-clip)"/>
              <!-- Border ring -->
              <circle cx="190" cy="270" r="90" fill="none" stroke="rgba(255,255,255,0.6)" stroke-width="4"/>
            SVG

            # Add LinkedIn-style #OPENTOWORK banner if this is an open to work card
            if should_show_open_to_work_banner?
              avatar_html += open_to_work_banner_svg
            end

            avatar_html
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

      # LinkedIn-style #OPENTOWORK banner at bottom of circular avatar (left-aligned)
      def open_to_work_banner_svg
        <<~SVG
          <!-- #OPENTOWORK Banner (LinkedIn style) - curved for circle -->
          <!-- Green curved banner background -->
          <ellipse cx="190" cy="355" rx="85" ry="23" fill="#16a34a"/>

          <!-- #OPENTOWORK text - positioned directly (no textPath for better compatibility) -->
          <text x="190" y="360" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="11" font-weight="700" letter-spacing="0.5">#OPENTOWORK</text>
        SVG
      end

      def default_avatar_svg
        avatar_html = <<~SVG
          <defs>
            <linearGradient id="avatar-bg" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style="stop-color:#a855f7;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#7c3aed;stop-opacity:1" />
            </linearGradient>
          </defs>
          <!-- White ring for contrast -->
          <circle cx="190" cy="270" r="95" fill="white" opacity="0.3"/>
          <!-- Avatar background circle -->
          <circle cx="190" cy="270" r="90" fill="url(#avatar-bg)"/>
          <!-- Icon -->
          <text x="190" y="300" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="70" font-weight="bold">👨‍💻</text>
          <!-- Border ring -->
          <circle cx="190" cy="270" r="90" fill="none" stroke="rgba(255,255,255,0.6)" stroke-width="4"/>
        SVG

        # Add LinkedIn-style #OPENTOWORK banner if this is an open to work card
        if should_show_open_to_work_banner?
          avatar_html += open_to_work_banner_svg
        end

        avatar_html
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

  def job_title_svg
    # Show job title if available, otherwise show first preferred role
    title_text = if @user.job_title.present?
      @user.job_title
    elsif @user.preferred_roles.any?
      @user.preferred_roles.first
    else
      "Developer"
    end

    <<~SVG
      <text x="380" y="185" fill="rgba(255,255,255,0.95)" font-family="Arial, sans-serif" font-size="28" font-weight="600">#{title_text}</text>
    SVG
  end

  def badge_svg
    if should_show_open_to_work_banner?
      # Green "AVAILABLE FOR HIRE" badge on right side
      <<~SVG
        <defs>
          <linearGradient id="open-badge" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#16a34a;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#15803d;stop-opacity:1" />
          </linearGradient>
        </defs>
        <rect x="380" y="220" width="260" height="46" rx="23" fill="url(#open-badge)" opacity="0.95"/>
        <text x="510" y="251" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="18" font-weight="800" letter-spacing="0.5">⚡ AVAILABLE FOR HIRE</text>
      SVG
    else
      ""  # No badge for regular profiles
    end
  end

  def work_info_section
    return "" unless should_show_open_to_work_banner?

    info_parts = []

    # Remote preference
    if @user.remote_preference.present?
      info_parts << "🎯 #{@user.remote_preference_label}"
    end

    # Availability
    if @user.availability.present?
      info_parts << "📅 #{@user.availability_label}"
    end

    # Work types (escape & for XML)
    if @user.work_types.any?
      types = @user.work_types_labels.first(2).join(" &amp; ")
      info_parts << "💼 #{types}"
    end

    html = ""
    y_pos = 310

    info_parts.each do |part|
      html += %(<text x="380" y="#{y_pos}" fill="rgba(255,255,255,0.95)" font-family="Arial, sans-serif" font-size="21" font-weight="600">#{part}</text>)
      y_pos += 35
    end

    html
  end

  def gradient_skills_svg(skills)
    return "" if skills.empty?

    html = ""
    html += %(<text x="380" y="450" fill="rgba(255,255,255,0.85)" font-family="Arial, sans-serif" font-size="16" font-weight="600">💻 SKILLS</text>)

    y_pos = 490
    x_pos = 380

    # Show up to 6 skills, 3 per row
    skills.first(6).each_with_index do |skill, index|
      # Move to second row after 3 skills
      if index == 3
        y_pos += 50
        x_pos = 380
      end

      width = skill.length * 10 + 25
      html += <<~SVG
        <rect x="#{x_pos}" y="#{y_pos}" width="#{width}" height="36" rx="18" fill="rgba(255,255,255,0.25)" stroke="rgba(255,255,255,0.4)" stroke-width="2"/>
        <text x="#{x_pos + width/2}" y="#{y_pos + 23}" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="15" font-weight="700">#{skill}</text>
      SVG
      x_pos += width + 12
    end

    html
  end

  def footer_svg
    <<~SVG
      <!-- Divider line -->
      <line x1="100" y1="590" x2="1100" y2="590" stroke="rgba(255,255,255,0.3)" stroke-width="2"/>

      <!-- CTA and branding -->
      <text x="100" y="620" fill="rgba(255,255,255,0.9)" font-family="Arial, sans-serif" font-size="18" font-weight="600">👉 Get in touch at devv.me/#{@user.username}</text>
      <text x="1070" y="620" text-anchor="end" fill="rgba(255,255,255,0.95)" font-family="Arial, sans-serif" font-size="24" font-weight="900">devv.me</text>
    SVG
  end

  def tagline_text
    if should_show_open_to_work_banner?
      # Generate compelling tagline for open to work profiles
      parts = []

      # Add availability
      if @user.availability.present?
        parts << @user.availability_label
      else
        parts << "Open to opportunities"
      end

      # Add remote preference
      if @user.remote_preference.present?
        parts << @user.remote_preference_label
      end

      # Add work types if available
      if @user.work_types.any?
        work_types = @user.work_types_labels.first(2).join(" & ")
        parts << work_types
      end

      # Join parts with bullet points
      parts.first(2).join(" • ")
    else
      # Default tagline for regular profiles
      "A developer profile worth sharing"
    end
  end

  def truncate_bio(bio_text, max_chars = 120)
    return "" unless bio_text.present?

    # Remove any HTML tags and normalize whitespace
    clean_bio = bio_text.strip.gsub(/<[^>]*>/, "").squeeze(" ")

    # Truncate if too long and add ellipsis
    if clean_bio.length > max_chars
      clean_bio = clean_bio[0...max_chars].strip + "..."
    end

    clean_bio
  end

  def escape_xml(text)
    return "" unless text.present?
    text.to_s.gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/>/, "&gt;")
  end

  def get_cached_image_for_version(version)
    # Look for existing cached image for this user and version
    cached_filename = "social_#{@user.id}_#{version}.png"
    cached_path = Rails.root.join("tmp", cached_filename)

    if File.exist?(cached_path)
      Rails.logger.info "Found cached image for user #{@user.id}, version #{version}"
      return cached_path
    end

    nil
  end

  # Helper method to determine if we should show open to work banner
  def should_show_open_to_work_banner?
    case @card_type
    when "hire", "open_to_work"
      true
    when "professional"
      @user.open_for_work?
    when "auto"
      @user.open_for_work?
    else
      false
    end
  end

  # Professional card helper methods
  def professional_avatar_svg
    if @user.avatar.attached?
      # Convert avatar to base64 for embedding in SVG
      begin
        avatar_data = @user.avatar.download
        avatar_base64 = Base64.strict_encode64(avatar_data)
        avatar_mime_type = @user.avatar.content_type

        <<~SVG
          <!-- Avatar with professional styling -->
          <defs>
            <clipPath id="professional-avatar-clip">
              <circle cx="190" cy="270" r="90"/>
            </clipPath>
          </defs>
          <circle cx="190" cy="270" r="90" fill="rgba(255,255,255,0.1)"/>
          <image x="100" y="180" width="180" height="180" href="data:#{avatar_mime_type};base64,#{avatar_base64}" clip-path="url(#professional-avatar-clip)"/>
          <!-- Professional border ring -->
          <circle cx="190" cy="270" r="90" fill="none" stroke="rgba(255,255,255,0.3)" stroke-width="3"/>
        SVG
      rescue => e
        Rails.logger.error "Failed to process avatar for user #{@user.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        professional_default_avatar_svg
      end
    else
      professional_default_avatar_svg
    end
  end

  def professional_default_avatar_svg
    <<~SVG
      <!-- Default professional avatar -->
      <circle cx="190" cy="270" r="90" fill="rgba(255,255,255,0.1)"/>
      <text x="190" y="300" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="70" font-weight="bold">👨‍💼</text>
      <!-- Professional border ring -->
      <circle cx="190" cy="270" r="90" fill="none" stroke="rgba(255,255,255,0.3)" stroke-width="3"/>
    SVG
  end

  def professional_job_title_svg
    title_text = @user.job_title.presence || @user.preferred_roles.first || "Developer"

    <<~SVG
      <text x="380" y="185" fill="rgba(255,255,255,0.95)" font-family="Arial, sans-serif" font-size="34" font-weight="700">#{title_text}</text>
    SVG
  end

  def professional_badge_svg
    if should_show_open_to_work_banner?
      <<~SVG
        <defs>
          <linearGradient id="open-badge-prof" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#16a34a;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#15803d;stop-opacity:1" />
          </linearGradient>
        </defs>
        <rect x="380" y="210" width="320" height="40" rx="20" fill="url(#open-badge-prof)" opacity="0.95"/>
        <text x="540" y="236" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="18" font-weight="800" letter-spacing="0.6">⚡ AVAILABLE FOR HIRE</text>
      SVG
    else
      # Professional badge - subtle and clean
      <<~SVG
        <defs>
          <linearGradient id="professional-badge" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#64748b;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#475569;stop-opacity:1" />
          </linearGradient>
        </defs>
        <rect x="380" y="210" width="320" height="40" rx="20" fill="url(#professional-badge)" stroke="rgba(255,255,255,0.25)" stroke-width="1"/>
        <text x="540" y="236" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="18" font-weight="800" letter-spacing="0.6">💼 PROFESSIONAL</text>
      SVG
    end
  end

  def professional_info_section
    # Get bio and location separately for multi-line display
    bio_text = @user.bio.present? ? truncate_bio(@user.bio, 70) : nil
    location_text = @user.location.present? ? "📍 #{@user.location}" : nil

    available_width = 720  # 1200 - 380 - 100 for right padding

    # Break into multiple lines if needed
    location_lines = wrap_text(location_text, available_width, 20) if location_text
    bio_lines = wrap_text("💬 #{bio_text}", available_width, 20) if bio_text

    html = ""
    y_pos = 280

    # Display location
    if location_lines
      location_lines.each_with_index do |line, idx|
        html += %(<tspan x="380" dy="#{idx == 0 ? '0' : '28'}">#{escape_xml(line)}</tspan>)
      end
      y_pos += location_lines.length * 28
    end

    # Display bio with proper spacing
    if bio_lines
      bio_lines.each_with_index do |line, idx|
        html += %(<tspan x="380" dy="#{idx == 0 ? '32' : '28'}">#{escape_xml(line)}</tspan>)
      end
    end

    <<~SVG
      <text x="380" y="280" fill="rgba(255,255,255,0.9)" font-family="Arial, sans-serif" font-size="20" font-weight="600">#{html}</text>
    SVG
  end

  def professional_skills_svg(skills)
    return "" if skills.empty?

    html = ""
    html += %(<text x="380" y="380" fill="rgba(255,255,255,0.95)" font-family="Arial, sans-serif" font-size="22" font-weight="700">🛠️ SKILLS &amp; EXPERTISE</text>)

    y_pos = 420
    x_pos = 380

    # Show up to 6 skills, 3 per row
    skills.first(6).each_with_index do |skill, index|
      if index > 0 && index % 3 == 0
        y_pos += 50
        x_pos = 380
      end

      width = skill.length * 10 + 28
      html += <<~SVG
        <rect x="#{x_pos}" y="#{y_pos}" width="#{width}" height="34" rx="17" fill="rgba(255,255,255,0.18)" stroke="rgba(255,255,255,0.28)" stroke-width="1"/>
        <text x="#{x_pos + width/2}" y="#{y_pos + 22}" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="16" font-weight="700">#{skill}</text>
      SVG
      x_pos += width + 18
    end

    html
  end

  def professional_footer_svg
    <<~SVG
      <!-- Divider line -->
      <line x1="100" y1="550" x2="1100" y2="550" stroke="rgba(255,255,255,0.2)" stroke-width="1"/>

      <!-- CTA and branding -->
      <text x="100" y="580" fill="rgba(255,255,255,0.8)" font-family="Arial, sans-serif" font-size="18" font-weight="600">👉 View full profile at devv.me/#{@user.username}</text>
      <text x="1070" y="580" text-anchor="end" fill="rgba(255,255,255,0.9)" font-family="Arial, sans-serif" font-size="24" font-weight="900">devv.me</text>
    SVG
  end

  def create_professional_svg_content(name, username, skills, job_title, bio, location)
    <<~SVG
      <svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <!-- Professional Gradient Background -->
          <linearGradient id="professional-bg" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#0f172a;stop-opacity:1" />
            <stop offset="55%" style="stop-color:#1e293b;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#334155;stop-opacity:1" />
          </linearGradient>

          <!-- Professional pattern overlay -->
          <pattern id="professional-dots" x="0" y="0" width="48" height="48" patternUnits="userSpaceOnUse">
            <circle cx="24" cy="24" r="1" fill="#ffffff" opacity="0.08"/>
          </pattern>

          <!-- Shadow for depth -->
          <filter id="professional-shadow" x="-50%" y="-50%" width="200%" height="200%">
            <feDropShadow dx="0" dy="6" stdDeviation="12" flood-color="#000000" flood-opacity="0.3"/>
          </filter>
        </defs>

        <!-- Professional Background -->
        <rect width="1200" height="630" fill="url(#professional-bg)"/>
        <rect width="1200" height="630" fill="url(#professional-dots)"/>

        <!-- Left Side: Avatar with shadow -->
        <g filter="url(#professional-shadow)">
          #{professional_avatar_svg}
        </g>

        <!-- Right Side: Content Area -->
        <g>
          <!-- Name -->
          <text x="380" y="140" fill="#ffffff" font-family="Arial, sans-serif" font-size="64" font-weight="900" letter-spacing="-0.5">#{name}</text>

          <!-- Job Title -->
          #{professional_job_title_svg}

          <!-- Professional Badge -->
          #{professional_badge_svg}

          <!-- Bio/Location Section -->
          #{professional_info_section}

          <!-- Skills -->
          #{professional_skills_svg(skills)}

          <!-- Footer -->
          #{professional_footer_svg}
        </g>
      </svg>
    SVG
  end
end
