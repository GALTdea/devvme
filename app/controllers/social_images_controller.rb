class SocialImagesController < ApplicationController
  # Skip authentication for public social images
  # No authentication needed for public social images

  # Serve clean social media card URLs with HTML pages for Twitter Cards
  def profile_card
    username = params[:username]
    card_type = params[:type] || "auto"
    Rails.logger.info "Social card HTML request for user: #{username}, card_type: #{card_type}"

    begin
      @user = User.friendly.find(username)

      # Check if user profile is accessible
      unless @user.active?
        render_not_found
        return
      end

      # Generate social image URL for the card
      @social_image_url = social_profile_image_url(
        username: @user.username,
        version: @user.social_image_cache_key,
        type: card_type
      )

      # Set up Twitter Card data
      @card_type = card_type
      @profile_url = public_profile_url(@user.friendly_id)

      # Generate card-specific title and description based on effective card type
      effective_card_type = determine_effective_card_type(card_type)

      case effective_card_type
      when "hire"
        @card_title = "#{@user.display_name} - Open to Work"
        @card_description = @user.work_status_message.presence || "Available for new opportunities"
      when "professional"
        @card_title = "#{@user.display_name} - Professional Profile"
        @card_description = @user.bio.presence || "Developer profile and portfolio"
      else
        @card_title = "#{@user.display_name} - Professional Profile"
        @card_description = @user.bio.presence || "Developer profile and portfolio"
      end

      # Render HTML page with Twitter Card meta tags
      render layout: false

    rescue ActiveRecord::RecordNotFound
      render_not_found
    end
  end

  # Serve social media images for profiles with path-based versioning
  def profile_image
    username = params[:username]
    version = params[:version] # Get the version parameter from path
    card_type = params[:type] || "auto" # Get the card type parameter, default to 'auto'
    Rails.logger.info "Looking for user with username: #{username}, version: #{version}, card_type: #{card_type}"

    begin
      user = User.friendly.find(username)
      Rails.logger.info "Found user: #{user.inspect}"

      # Check if user profile is accessible
      unless user.active?
        render_not_found
        return
      end

      # Generate or retrieve cached social image for this specific version and card type
      social_image_path = generate_social_image(user, version, card_type)

      # Check if it's a URL or a file path
      if social_image_path.to_s.start_with?("http")
        # It's a URL, redirect to it
        redirect_to social_image_path
      elsif File.exist?(social_image_path)
        # It's a file path, serve the file
        file_type = social_image_path.to_s.end_with?(".svg") ? "image/svg+xml" : "image/png"
        file_extension = social_image_path.to_s.end_with?(".svg") ? "svg" : "png"

        send_file social_image_path,
                  type: file_type,
                  disposition: "inline",
                  filename: generate_download_filename(username, version, card_type, file_extension)
      else
        render_not_found
      end

    rescue ActiveRecord::RecordNotFound
      render_not_found
    end
  end

  # Legacy method for social media images without version (redirects to current version)
  def profile_image_legacy
    username = params[:username]
    Rails.logger.info "Legacy request for user with username: #{username}"

    begin
      user = User.friendly.find(username)

      # Check if user profile is accessible
      unless user.active?
        render_not_found
        return
      end

      # Redirect to the current version
      redirect_to social_profile_image_path(username: username, version: user.social_image_cache_key), status: :moved_permanently

    rescue ActiveRecord::RecordNotFound
      render_not_found
    end
  end

  # Serve main site social media image
  def main_image
    # Serve a static branded image for the main site
    main_image_path = Rails.root.join("public", "images", "main-social-image.png")

    if File.exist?(main_image_path)
      send_file main_image_path,
                type: "image/png",
                disposition: "inline",
                filename: "devvme_main_social_image.png"
    else
      # Return 404 if image doesn't exist
      head :not_found
    end
  end

  private

  def generate_social_image(user, version = nil, card_type = "auto")
    # Use the social image generator service with version and card type
    service = SocialImageGeneratorService.new(user, card_type)
    service.generate_profile_image(version)
  end

  def generate_download_filename(username, version, card_type, file_extension)
    # Use single filename pattern for all card types (dynamic content)
    "#{username}_social_image_v#{version}.#{file_extension}"
  end

  def determine_effective_card_type(card_type)
    # Determine the effective card type based on the requested type and user status
    case card_type
    when "hire", "open_to_work"
      "hire"
    when "professional"
      "professional"
    when "auto"
      # Auto mode: show hire card if user is open for work, otherwise professional
      @user.open_to_work? ? "hire" : "professional"
    else
      # Default to professional card
      "professional"
    end
  end

  def render_not_found
    # Return a 404 with a default social image
    default_image_path = Rails.root.join("public", "images", "default-social-image.png")

    if File.exist?(default_image_path)
      send_file default_image_path,
                type: "image/png",
                disposition: "inline"
    else
      head :not_found
    end
  end
end
