# Security Configuration
# This file contains security-related configurations for the DevvMe application

Rails.application.configure do
  # =============================================================================
  # Content Security Policy (CSP)
  # =============================================================================

  # Configure Content Security Policy to prevent XSS attacks
  config.content_security_policy do |policy|
    # Default policy
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, "blob:"
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline, :unsafe_eval
    policy.style_src   :self, :https, :unsafe_inline
    policy.connect_src :self, :https
    policy.frame_src   :none
    policy.base_uri    :self

    # Allow specific external domains for analytics and social sharing
    if ENV["GOOGLE_ANALYTICS_ID"].present?
      policy.script_src :self, :https, :unsafe_inline, "https://www.googletagmanager.com"
      policy.connect_src :self, :https, "https://www.google-analytics.com"
    end

    # Allow social media sharing
    policy.img_src :self, :https, :data, "https://platform.linkedin.com", "https://abs.twimg.com"

    # Report violations in production
    if Rails.env.production?
      policy.report_uri "/csp-violation-report"
    end
  end

  # =============================================================================
  # Security Headers
  # =============================================================================

  # Force HTTPS in production
  if Rails.env.production?
    config.force_ssl = true
  end

  # =============================================================================
  # Rate Limiting (if using rack-attack gem)
  # =============================================================================

  # Uncomment if you add rack-attack gem
  # config.middleware.use Rack::Attack

  # =============================================================================
  # Session Security
  # =============================================================================

  # Secure session cookies
  config.session_store :cookie_store,
    key: "_devvme_session",
    secure: Rails.env.production?,
    httponly: true,
    same_site: :lax

  # =============================================================================
  # CORS Configuration (if needed for API)
  # =============================================================================

  # Uncomment and configure if you need CORS
  # config.middleware.insert_before 0, Rack::Cors do
  #   allow do
  #     origins ENV.fetch("ALLOWED_ORIGINS", "").split(",")
  #     resource "*", headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head]
  #   end
  # end
end

# =============================================================================
# Environment Variable Validation
# =============================================================================

# Validate required environment variables in production
if Rails.env.production?
  required_vars = %w[
    RAILS_MASTER_KEY
    DATABASE_URL
    CACHE_DATABASE_URL
    QUEUE_DATABASE_URL
    CABLE_DATABASE_URL
    SMTP_USERNAME
    SMTP_PASSWORD
  ]

  missing_vars = required_vars.select { |var| ENV[var].blank? }

  if missing_vars.any?
    raise "Missing required environment variables: #{missing_vars.join(', ')}"
  end
end

# =============================================================================
# Security Monitoring
# =============================================================================

# Log security events
Rails.logger.info "Security configuration loaded for #{Rails.env} environment"

# Log missing optional security configurations
if Rails.env.production?
  optional_security_vars = %w[GOOGLE_ANALYTICS_ID FACEBOOK_APP_ID IPINFO_TOKEN]
  missing_optional = optional_security_vars.select { |var| ENV[var].blank? }

  if missing_optional.any?
    Rails.logger.warn "Optional security variables not set: #{missing_optional.join(', ')}"
  end
end
