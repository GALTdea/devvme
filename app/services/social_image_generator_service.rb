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

    svg_content = <<~SVG
      <svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
            <stop offset="50%" style="stop-color:#764ba2;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#f093fb;stop-opacity:1" />
          </linearGradient>
          <linearGradient id="card" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#ffffff;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#f8fafc;stop-opacity:1" />
          </linearGradient>
          <linearGradient id="badge" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
          </linearGradient>
        </defs>

        <!-- Background -->
        <rect width="1200" height="630" fill="url(#bg)"/>

        <!-- Background pattern -->
        <pattern id="dots" x="0" y="0" width="80" height="80" patternUnits="userSpaceOnUse">
          <circle cx="40" cy="40" r="3" fill="white" opacity="0.15"/>
        </pattern>
        <rect width="1200" height="630" fill="url(#dots)"/>

        <!-- Main card with shadow -->
        <rect x="100" y="65" width="1000" height="500" rx="24" fill="url(#card)" stroke="rgba(255,255,255,0.3)" stroke-width="2"/>
        <rect x="100" y="65" width="1000" height="500" rx="24" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>

        <!-- Avatar -->
        #{avatar_svg}

        <!-- Badge with improved styling -->
        <rect x="348" y="113" width="200" height="36" rx="18" fill="url(#badge)"/>
        <text x="448" y="137" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="14" font-weight="700">DEVELOPER PROFILE</text>

        <!-- Name with better contrast -->
        <text x="348" y="200" fill="#1a202c" font-family="Arial, sans-serif" font-size="48" font-weight="800">#{name}</text>

        <!-- Username with better styling -->
        <text x="348" y="240" fill="#4a5568" font-family="Arial, sans-serif" font-size="24" font-weight="600">@#{username}</text>

        <!-- Tagline with better visibility -->
        <text x="348" y="280" fill="#2d3748" font-family="Arial, sans-serif" font-size="20" font-weight="600">A developer profile worth sharing</text>

        <!-- Skills -->
        #{skills_svg(skills)}

        <!-- Branding with better visibility -->
        <text x="1076" y="590" text-anchor="end" fill="#667eea" font-family="Arial, sans-serif" font-size="18" font-weight="700">devv.me</text>
      </svg>
    SVG

    # Save SVG to file first
    svg_filename = "social_#{@user.id}_#{Time.current.to_i}.svg"
    svg_path = Rails.root.join("tmp", svg_filename)
    File.write(svg_path, svg_content)

    # Convert SVG to PNG for better social media compatibility
    png_filename = "social_#{@user.id}_#{Time.current.to_i}.png"
    png_path = Rails.root.join("tmp", png_filename)

    # Use ImageMagick to convert SVG to PNG
    # Use convert command for ImageMagick v6 (Hatchbox default)
    Rails.logger.info "Converting SVG to PNG with ImageMagick"
    conversion_result = system("convert -background transparent -size 1200x630 -type TrueColor #{svg_path} #{png_path}")
    Rails.logger.info "ImageMagick conversion result: #{conversion_result}"

    # Debug: Check if conversion worked
    if File.exist?(png_path)
      file_info = `file #{png_path}`.strip
      Rails.logger.info "ImageMagick conversion result: #{file_info}"

      # If it's still 1-bit, try alternative approach
      if file_info.include?("1-bit")
        Rails.logger.info "Retrying with different ImageMagick options"
        system("convert -background transparent -size 1200x630 -depth 8 -type TrueColorAlpha #{svg_path} #{png_path}")
      end

      # Clean up the SVG file only if PNG conversion succeeded
      File.delete(svg_path) if File.exist?(svg_path)
      png_path
    else
      # Conversion failed, return SVG path and keep the SVG file
      Rails.logger.warn "ImageMagick conversion failed, returning SVG file"
      svg_path
    end
  end

      def avatar_svg
        if @user.avatar.attached?
          # Convert avatar to base64 for embedding in SVG
          begin
            avatar_data = @user.avatar.download
            avatar_base64 = Base64.encode64(avatar_data).gsub(/\n/, "")
            avatar_mime_type = @user.avatar.content_type

            <<~SVG
              <defs>
                <clipPath id="avatar-clip">
                  <rect x="148" y="113" width="160" height="160" rx="20"/>
                </clipPath>
              </defs>
              <image x="148" y="113" width="160" height="160" href="data:#{avatar_mime_type};base64,#{avatar_base64}" clip-path="url(#avatar-clip)"/>
              <rect x="148" y="113" width="160" height="160" rx="20" fill="none" stroke="#667eea" stroke-width="3"/>
            SVG
          rescue => e
            Rails.logger.error "Failed to process avatar for user #{@user.id}: #{e.message}"
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
              <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
            </linearGradient>
          </defs>
          <rect x="148" y="113" width="160" height="160" rx="20" fill="url(#avatar-bg)"/>
          <circle cx="228" cy="173" r="50" fill="rgba(255,255,255,0.2)"/>
          <text x="228" y="200" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="60" font-weight="bold">👨‍💻</text>
          <rect x="148" y="113" width="160" height="160" rx="20" fill="none" stroke="#ffffff" stroke-width="3"/>
        SVG
      end

  def skills_svg(skills)
    return "" if skills.empty?

    y_pos = 320
    skills_html = ""

    skills.each_with_index do |skill, index|
      x_pos = 348 + (index * 130)
      skills_html += <<~SVG
        <rect x="#{x_pos}" y="#{y_pos}" width="110" height="28" rx="14" fill="rgba(102,126,234,0.15)" stroke="rgba(102,126,234,0.3)" stroke-width="1"/>
        <text x="#{x_pos + 55}" y="#{y_pos + 18}" text-anchor="middle" fill="#667eea" font-family="Arial, sans-serif" font-size="13" font-weight="600">#{skill}</text>
      SVG
    end

    skills_html
  end
end
