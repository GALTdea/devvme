class SocialImagesController < ApplicationController
  # Skip authentication for public social images
  # No authentication needed for public social images

  # Serve social media images for profiles with path-based versioning
  def profile_image
    username = params[:username]
    version = params[:version] # Get the version parameter from path
    Rails.logger.info "Looking for user with username: #{username}, version: #{version}"

    begin
      user = User.friendly.find(username)
      Rails.logger.info "Found user: #{user.inspect}"

      # Check if user profile is accessible
      unless user.active?
        render_not_found
        return
      end

      # Generate or retrieve cached social image for this specific version
      social_image_path = generate_social_image(user, version)

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
                  filename: "#{username}_social_image_v#{version}.#{file_extension}"
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

  def generate_social_image(user, version = nil)
    # Use the social image generator service with version
    service = SocialImageGeneratorService.new(user)
    service.generate_profile_image(version)
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
