class PublicProfilesController < ApplicationController
  before_action :set_user
  before_action :set_cache_headers

  # Display public user profile page that can be shared with visitors
  # Accessible at /:username (e.g., /gustavo)
  def show
    # If current user is viewing their own profile, redirect to authenticated profile
    if user_signed_in? && @user == current_user
      redirect_to profile_path
      return
    end

    # Only show published projects to public visitors
    @recent_projects = @user.projects.published.recent.limit(6)

    # Set SEO meta tags
    set_seo_meta_tags
  end

  private

  # Find user by username using FriendlyId
  # Returns 404 if user not found
  def set_user
    @user = User.friendly.find(params[:username])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end

  # Set cache headers for better performance
  def set_cache_headers
    # Cache public profiles for 15 minutes
    expires_in 15.minutes, public: true

    # Add ETag based on user updated_at timestamp
    fresh_when(@user, public: true) if @user
  end

  # Set comprehensive SEO meta tags for profile pages
  def set_seo_meta_tags
    # Basic meta description
    description = if @user.bio.present?
                   truncate(strip_tags(@user.bio), length: 155)
                 else
                   "View #{@user.display_name}'s profile and projects on Devvme App. #{@user.published_projects_count} published projects."
                 end

    # Keywords based on user's profile
    keywords = [
      @user.username,
      @user.display_name,
      "developer",
      "portfolio",
      "projects",
      "profile"
    ].compact.join(", ")

    # Set page title
    page_title("#{@user.display_name} (@#{@user.username})")

    # Set meta description
    meta_description(description)

    # Set meta keywords
    meta_keywords(keywords)

    # Set canonical URL
    canonical_url(public_profile_url(@user.username))

    # Set Open Graph tags
    avatar_url = @user.avatar.attached? ? url_for(@user.avatar) : nil
    open_graph_tags(
      title: "#{@user.display_name} - Developer Profile",
      description: description,
      image: avatar_url,
      url: public_profile_url(@user.username),
      type: "profile"
    )

    # Set Twitter Card tags
    twitter_card_tags(
      title: "#{@user.display_name} (@#{@user.username})",
      description: description,
      image: avatar_url
    )

    # Set structured data for profile
    set_profile_structured_data
  end

  # Generate JSON-LD structured data for the profile
  def set_profile_structured_data
    content_for :structured_data do
      schema = {
        "@context": "https://schema.org",
        "@type": "Person",
        "name": @user.display_name,
        "alternateName": "@#{@user.username}",
        "description": @user.bio.presence || "Developer on Devvme App",
        "url": public_profile_url(@user.username),
        "memberOf": {
          "@type": "Organization",
          "name": "Devvme App"
        }
      }

      # Add image if avatar exists
      if @user.avatar.attached?
        schema[:image] = url_for(@user.avatar)
      end

      # Add social media profiles
      same_as = []
      same_as << @user.github_url if @user.github_url.present?
      same_as << @user.linkedin_url if @user.linkedin_url.present?
      same_as << @user.website_url if @user.website_url.present?
      schema[:sameAs] = same_as if same_as.any?

      # Add projects as CreativeWork
      if @recent_projects.any?
        schema[:hasCreatedWork] = @recent_projects.map do |project|
          {
            "@type": "CreativeWork",
            "name": project.title,
            "description": project.description,
            "dateCreated": project.created_at.iso8601,
            "creator": {
              "@type": "Person",
              "name": @user.display_name
            }
          }
        end
      end

      content_tag :script, schema.to_json.html_safe, type: "application/ld+json"
    end
  end
end
