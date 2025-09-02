# Visitor Tracking Configuration

# Visitor tracking middleware is configured in config/application.rb

# Configuration options
VISITOR_TRACKING_CONFIG = {
  # Enable/disable tracking
  enabled: Rails.env.production? || Rails.env.development?,

  # Cookie settings
  cookie_duration: 90.days,
  cookie_secure: Rails.env.production?,

  # Tracking exclusions
  exclude_paths: [
    /^\/admin/,
    /^\/api/,
    /^\/rails/,
    /\.json$/,
    /\.xml$/,
    /\.rss$/
  ],

  # File extensions to ignore
  static_extensions: %w[.css .js .png .jpg .jpeg .gif .ico .svg .woff .woff2 .ttf .eot .map],

  # Bot patterns to exclude
  bot_patterns: [
    "bot", "crawler", "spider", "scraper", "facebookexternalhit",
    "twitterbot", "linkedinbot", "googlebot", "bingbot", "yandexbot",
    "slurp", "duckduckbot", "baiduspider"
  ]
}.freeze
