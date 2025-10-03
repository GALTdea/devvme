class HomeController < ApplicationController
  def index
    # Redirect authenticated users to dashboard
    redirect_to dashboard_path if user_signed_in?

    # Prepare SEO data for social media cards
    prepare_seo_data
  end

  private

  def prepare_seo_data
    # SEO data for the main landing page
    @seo_title = "Devv.me - Showcase, Connect, and Grow as a Developer"
    @seo_description = "Showcase your work, grow your network, and connect with developers who share your passions. Build your developer portfolio and join a vibrant community."
    @seo_url = root_url
    @seo_image_url = main_social_image_url
  end
end
