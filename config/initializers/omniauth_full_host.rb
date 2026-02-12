# frozen_string_literal: true

# Set OmniAuth full_host so the OAuth callback URL is built with the correct host.
# GitHub (and other providers) require the redirect_uri to exactly match a URL
# registered in the OAuth app; without this, callbacks can use the wrong host.
if Rails.env.development?
  OmniAuth.config.full_host = ENV.fetch("OMNIAUTH_FULL_HOST", "http://localhost:3000")
elsif Rails.env.production?
  opts = Rails.application.config.action_controller.default_url_options
  if opts[:host].present?
    protocol = opts[:protocol] || "https"
    OmniAuth.config.full_host = "#{protocol}://#{opts[:host]}"
  end
end
