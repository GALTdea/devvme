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
            <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
          </linearGradient>
          <linearGradient id="card" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#ffffff;stop-opacity:0.95" />
            <stop offset="100%" style="stop-color:#ffffff;stop-opacity:0.9" />
          </linearGradient>
        </defs>

        <!-- Background -->
        <rect width="1200" height="630" fill="url(#bg)"/>

        <!-- Background pattern -->
        <pattern id="dots" x="0" y="0" width="60" height="60" patternUnits="userSpaceOnUse">
          <circle cx="30" cy="30" r="2" fill="white" opacity="0.1"/>
        </pattern>
        <rect width="1200" height="630" fill="url(#dots)"/>

        <!-- Main card -->
        <rect x="100" y="65" width="1000" height="500" rx="24" fill="url(#card)" stroke="rgba(255,255,255,0.2)" stroke-width="1"/>

        <!-- Avatar -->
        #{avatar_svg}

        <!-- Badge -->
        <rect x="348" y="113" width="180" height="32" rx="16" fill="#667eea"/>
        <text x="438" y="135" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="14" font-weight="600">DEVELOPER PROFILE</text>

        <!-- Name -->
        <text x="348" y="200" fill="#1a202c" font-family="Arial, sans-serif" font-size="48" font-weight="700">#{name}</text>

        <!-- Username -->
        <text x="348" y="240" fill="#4a5568" font-family="Arial, sans-serif" font-size="24" font-weight="500">@#{username}</text>

        <!-- Tagline -->
        <text x="348" y="280" fill="#2d3748" font-family="Arial, sans-serif" font-size="20" font-weight="500">A developer profile worth sharing</text>

        <!-- Skills -->
        #{skills_svg(skills)}

        <!-- Branding -->
        <text x="1076" y="590" text-anchor="end" fill="rgba(255,255,255,0.8)" font-family="Arial, sans-serif" font-size="16" font-weight="500">devv.me</text>
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
    # Use magick command for ImageMagick v7+ with proper color depth
    conversion_result = system("magick -background transparent -size 1200x630 -type TrueColor #{svg_path} #{png_path}")

    # Debug: Check if conversion worked
    if File.exist?(png_path)
      file_info = `file #{png_path}`.strip
      Rails.logger.info "ImageMagick conversion result: #{file_info}"

      # If it's still 1-bit, try alternative approach
      if file_info.include?("1-bit")
        Rails.logger.info "Retrying with different ImageMagick options"
        system("magick -background transparent -size 1200x630 -depth 8 -type TrueColorAlpha #{svg_path} #{png_path}")
      end
    end

    # Clean up the SVG file
    File.delete(svg_path) if File.exist?(svg_path)

    # Return PNG path if conversion succeeded, otherwise return SVG path
    File.exist?(png_path) ? png_path : svg_path
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
          <rect x="148" y="113" width="160" height="160" rx="20" fill="#667eea"/>
          <text x="228" y="200" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="80" font-weight="bold">👨‍💻</text>
        SVG
      end

  def skills_svg(skills)
    return "" if skills.empty?

    y_pos = 320
    skills_html = ""

    skills.each_with_index do |skill, index|
      x_pos = 348 + (index * 120)
      skills_html += <<~SVG
        <rect x="#{x_pos}" y="#{y_pos}" width="100" height="24" rx="12" fill="rgba(102,126,234,0.1)" stroke="rgba(102,126,234,0.2)" stroke-width="1"/>
        <text x="#{x_pos + 50}" y="#{y_pos + 16}" text-anchor="middle" fill="#667eea" font-family="Arial, sans-serif" font-size="12" font-weight="500">#{skill}</text>
      SVG
    end

    skills_html
  end
end
