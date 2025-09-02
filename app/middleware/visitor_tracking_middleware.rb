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
    # Only track successful HTML requests
    return false unless status == 200
    return false unless html_request?(request)
    return false if admin_path?(request)
    return false if api_path?(request)
    return false if static_asset?(request)

    true
  end

  def html_request?(request)
    # Check if the request accepts HTML
    request.format.html? || request.headers['Accept']&.include?('text/html')
  end

  def admin_path?(request)
    request.path.start_with?('/admin')
  end

  def api_path?(request)
    request.path.start_with?('/api')
  end

  def static_asset?(request)
    path = request.path
    static_extensions = %w[.css .js .png .jpg .jpeg .gif .ico .svg .woff .woff2 .ttf .eot .map]
    static_extensions.any? { |ext| path.end_with?(ext) }
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
