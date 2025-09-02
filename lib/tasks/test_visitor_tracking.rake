namespace :visitor_tracking do
  desc "Test visitor tracking functionality"
  task test: :environment do
    puts "🧪 Testing Visitor Tracking System..."
    puts "=" * 40

    # Test 1: Create a mock visitor
    puts "\n1️⃣ Testing visitor creation..."
    initial_count = Visitor.count

    # Simulate a request
    mock_request = MockRequest.new
    service = VisitorTrackingService.new(mock_request)
    visitor = service.track_page_view('/', page_title: 'Test Home Page')

    if Visitor.count > initial_count
      puts "✅ Visitor created successfully"
      puts "   Visitor ID: #{visitor.visitor_id[0..8]}..."
      puts "   Page views: #{visitor.page_views}"
    else
      puts "❌ Failed to create visitor"
    end

    # Test 2: Test analytics methods
    puts "\n2️⃣ Testing analytics methods..."

    analytics = {
      'Total visitors' => Visitor.total_visitors,
      'Unique visitors (7 days)' => Visitor.unique_visitors(7),
      'Conversion rate (30 days)' => Visitor.conversion_rate(30),
      'Average time on site' => Visitor.average_time_on_site(30),
      'Total page views (7 days)' => VisitorPageView.total_page_views(7)
    }

    analytics.each do |metric, value|
      puts "   #{metric}: #{value}"
    end

    # Test 3: Test recent data
    puts "\n3️⃣ Recent visitor activity..."
    recent_visitors = Visitor.recent.limit(3)

    if recent_visitors.any?
      recent_visitors.each_with_index do |v, index|
        puts "   #{index + 1}. #{v.visitor_id[0..8]}... - #{v.page_views} pages - #{v.country || 'Unknown location'}"
      end
      puts "✅ Recent visitor data available"
    else
      puts "⚠️  No recent visitors found"
    end

    puts "\n✨ Visitor tracking test completed!"
  end
end

# Mock request class for testing
class MockRequest
  def initialize
    @session_data = {}
    @cookies_data = {}
  end

  def session
    @session ||= MockSession.new(@session_data)
  end

  def cookies
    @cookies ||= MockCookies.new(@cookies_data)
  end

  def cookie_jar
    cookies
  end

  def user_agent
    'Mozilla/5.0 (Test Browser) AppleWebKit/537.36'
  end

  def referer
    'https://google.com'
  end

  def remote_ip
    '192.168.1.100'
  end

  def ip
    remote_ip
  end

  def headers
    {
      'HTTP_X_FORWARDED_FOR' => remote_ip,
      'HTTP_X_REAL_IP' => remote_ip
    }
  end

  def path
    '/'
  end

  def env
    {}
  end

  def respond_to?(method)
    [:session, :cookies, :cookie_jar, :user_agent, :referer, :remote_ip, :ip, :headers, :path, :env].include?(method) || super
  end

  class MockSession
    def initialize(data)
      @data = data
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      @data[key] = value
    end

    def id
      @data[:session_id] ||= SecureRandom.hex(16)
    end
  end

  class MockCookies
    def initialize(data)
      @data = data
    end

    def [](key)
      @data[key]
    end

    def []=(key, value_or_options)
      if value_or_options.is_a?(Hash)
        @data[key] = value_or_options[:value]
      else
        @data[key] = value_or_options
      end
    end
  end
end
