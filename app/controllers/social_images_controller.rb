class SocialImagesController < ApplicationController
  # Skip authentication for public social images
  # No authentication needed for public social images

  # Serve social media images for profiles
  def profile_image
    username = params[:username]
    Rails.logger.info "Looking for user with username: #{username}"

    begin
      user = User.friendly.find(username)
      Rails.logger.info "Found user: #{user.inspect}"

      # Check if user profile is accessible
      unless user.active?
        render_not_found
        return
      end

      # Generate or retrieve cached social image
      social_image_path = generate_social_image(user)

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
                  filename: "#{username}_social_image.#{file_extension}"
      else
        render_not_found
      end

    rescue ActiveRecord::RecordNotFound
      render_not_found
    end
  end

  # Serve main site social media image
  def main_image
    # Generate or retrieve cached dynamic main social image
    title = params[:title].presence || "Devv.me — Build a standout developer profile"
    subtitle = params[:subtitle].presence || "Showcase projects, get discovered, and grow your developer brand."

    begin
      generator = MainSocialImageGenerator.new(title: title, subtitle: subtitle)
      image_path = generator.generate

      file_type = image_path.to_s.end_with?(".svg") ? "image/svg+xml" : "image/png"
      file_extension = image_path.to_s.end_with?(".svg") ? "svg" : "png"

      send_file image_path,
                type: file_type,
                disposition: "inline",
                filename: "devvme_main_social_image.#{file_extension}"
    rescue => e
      Rails.logger.error "Failed to generate main social image: #{e.message}"
      fallback_path = Rails.root.join("public", "images", "main-social-image.png")
      if File.exist?(fallback_path)
        send_file fallback_path, type: "image/png", disposition: "inline", filename: "devvme_main_social_image.png"
      else
        head :not_found
      end
    end
  end

  private

  def generate_social_image(user)
    # Use the social image generator service
    service = SocialImageGeneratorService.new(user)
    service.generate_profile_image
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
