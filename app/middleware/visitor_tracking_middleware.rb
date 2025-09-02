# VisitorTrackingMiddleware
#
# Purpose:
# This middleware tracks page views and visitor analytics across the application.
# It captures visitor data for analytics purposes while maintaining performance
# by processing tracking asynchronously.
#
# How it works:
# 1. Intercepts all HTTP requests before they reach the application
# 2. Allows the request to be processed normally by the Rails application
# 3. After a successful response (200 status), evaluates if the request should be tracked
# 4. For trackable requests, extracts visitor data and queues a background job
# 5. The background job (VisitorTrackingJob) handles the actual database storage
#
# Tracking criteria:
# - Only tracks successful HTML requests (status 200)
# - Excludes admin paths, API endpoints, and static assets
# - Respects the VISITOR_TRACKING_CONFIG settings
#
# Data collected:
# - Page path and title
# - IP address (with proxy support)
# - User agent and referrer
# - Session and visitor identifiers
#
# Performance considerations:
# - Uses background jobs to avoid blocking the request/response cycle
# - Includes error handling to prevent tracking failures from breaking requests
# - Configurable exclusion patterns to avoid tracking unnecessary requests
#
class VisitorTrackingMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    # Process the request first
    status, headers, response = @app.call(env)

    # Track page view after successful response (only for HTML pages)
    if should_track_request?(request, status)
      track_page_view_async(request)
    end

    [status, headers, response]
  rescue => e
    # Log error but don't break the request
    Rails.logger.error "Visitor tracking error: #{e.message}"
    [status, headers, response] if defined?(status)
  end

  private

    def should_track_request?(request, status)
    # Check if tracking is enabled
    return false unless VISITOR_TRACKING_CONFIG[:enabled]

    # Only track successful HTML requests
    return false unless status == 200
    return false unless html_request?(request)
    return false if excluded_path?(request)
    return false if static_asset?(request)

    true
  end

  def html_request?(request)
    # Check if the request accepts HTML
    request.format.html? || request.headers['Accept']&.include?('text/html')
  end

  def excluded_path?(request)
    path = request.path
    VISITOR_TRACKING_CONFIG[:exclude_paths].any? { |pattern| path.match?(pattern) }
  end

  def static_asset?(request)
    path = request.path
    VISITOR_TRACKING_CONFIG[:static_extensions].any? { |ext| path.end_with?(ext) }
  end

  def track_page_view_async(request)
    # Use a background job to avoid slowing down the request
    VisitorTrackingJob.perform_later(
      request.path,
      extract_page_title(request),
      serialize_request_data(request)
    )
  end

  def extract_page_title(request)
    # Try to extract page title from common patterns
    case request.path
    when '/'
      'Home'
    when '/blog'
      'Blog'
    when %r{^/blog/(\d+)}
      'Blog Post'
    when %r{^/([^/]+)$}
      'Profile'
    else
      request.path.split('/').last&.humanize || 'Unknown'
    end
  end

  def serialize_request_data(request)
    {
      ip_address: request.headers['HTTP_X_FORWARDED_FOR']&.split(',')&.first&.strip || request.remote_ip,
      user_agent: request.user_agent,
      referrer: request.referer,
      session_id: request.session.id.to_s,
      visitor_id: request.session[:visitor_id] || request.cookies[:visitor_id]
    }
  end
end
