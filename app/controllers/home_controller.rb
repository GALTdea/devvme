class HomeController < ApplicationController
  def index
    # Redirect authenticated users to dashboard
    redirect_to dashboard_path if user_signed_in?

    # Fetch featured users for homepage showcase
    @featured_users = User.featured
                         .where.not(username: nil)
                         .where(account_status: [:active, :invited])
                         .limit(10)
                         .order("RANDOM()")

    # Prepare SEO data for social media cards
    prepare_seo_data
  end

  private

  def prepare_seo_data
    # SEO data for the main landing page
    @seo_title = "Devv.me — Build a standout developer profile"
    @seo_description = "Showcase projects, get discovered by peers and teams, and grow your developer brand. Create a beautiful portfolio in minutes with social‑ready links."
    @seo_url = root_url
    @seo_image_url = main_social_image_url(host: request.base_url)
  end
end
