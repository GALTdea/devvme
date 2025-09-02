class VisitorTrackingService
  attr_reader :request, :visitor

  def initialize(request)
    @request = request
    @visitor = find_or_create_visitor
  end

  def track_page_view(page_path, page_title: nil)
    return unless should_track?

    # Update visitor's last visit
    @visitor.update_visit! if returning_visitor?

    # Track the page view
    @visitor.add_page_view!(
      page_path,
      page_title: page_title,
      referrer: request.referer,
      time_on_page: 0 # Will be updated via JavaScript
    )

    # Update location info if not present
    update_location_info if should_update_location?

    @visitor
  end

  def mark_conversion!(user)
    @visitor.mark_as_converted!(user)
  end

  def self.track_page_view(request, page_path, page_title: nil)
    service = new(request)
    service.track_page_view(page_path, page_title: page_title)
  end

  def self.mark_conversion!(request, user)
    service = new(request)
    service.mark_conversion!(user)
  end

  private

  def find_or_create_visitor
    visitor_id = get_visitor_id_from_session || get_visitor_id_from_cookie

    if visitor_id
      visitor = Visitor.find_by(visitor_id: visitor_id)
      return visitor if visitor
    end

    create_new_visitor
  end

  def create_new_visitor
    visitor_id = SecureRandom.uuid

    visitor = Visitor.create!(
      visitor_id: visitor_id,
      ip_address: get_ip_address,
      user_agent: request.user_agent,
      referrer: request.referer,
      first_visit_at: Time.current,
      last_visit_at: Time.current
    )

    # Store visitor ID in session and cookie
    store_visitor_id(visitor_id)

    visitor
  end

  def get_visitor_id_from_session
    return nil unless request.session
    request.session[:visitor_id]
  end

  def get_visitor_id_from_cookie
    return nil unless request.cookies
    request.cookies[:visitor_id]
  end

  def store_visitor_id(visitor_id)
    # Store in session (temporary)
    request.session[:visitor_id] = visitor_id if request.session

    # Store in cookie (persistent, 90 days)
    if request.respond_to?(:cookie_jar)
      request.cookie_jar[:visitor_id] = {
        value: visitor_id,
        expires: 90.days.from_now,
        httponly: true,
        secure: Rails.env.production?
      }
    end
  end

  def returning_visitor?
    @visitor.persisted? && @visitor.last_visit_at < 30.minutes.ago
  end

  def should_track?
    # Don't track admin users or bots
    return false if current_user_is_admin?
    return false if bot_request?
    return false if static_asset?

    true
  end

  def should_update_location?
    @visitor.country.blank? && @visitor.city.blank?
  end

  def update_location_info
    return unless @visitor.country.blank? && @visitor.city.blank?

    ip_address = get_ip_address
    return if ip_address.blank?

    # Use background job for geolocation to avoid slowing down requests
    GeolocationJob.perform_later(@visitor.id, ip_address)
  end

  def current_user_is_admin?
    # Check if current user is logged in and is admin
    return false unless request.env["warden"]

    user = request.env["warden"].user
    user&.can_access_admin?
  end

  def bot_request?
    return false unless request.user_agent

    user_agent = request.user_agent.downcase
    bot_patterns = [
      "bot", "crawler", "spider", "scraper", "facebookexternalhit",
      "twitterbot", "linkedinbot", "googlebot", "bingbot", "yandexbot",
      "slurp", "duckduckbot", "baiduspider"
    ]

    bot_patterns.any? { |pattern| user_agent.include?(pattern) }
  end

  def static_asset?
    path = request.path
    return false unless path

    # Don't track static assets
    static_extensions = %w[.css .js .png .jpg .jpeg .gif .ico .svg .woff .woff2 .ttf .eot]
    static_extensions.any? { |ext| path.end_with?(ext) }
  end

  def get_ip_address
    # Get real IP address, handling proxies and load balancers
    request.headers["HTTP_X_FORWARDED_FOR"]&.split(",")&.first&.strip ||
      request.headers["HTTP_X_REAL_IP"] ||
      request.remote_ip ||
      request.ip
  end
end
