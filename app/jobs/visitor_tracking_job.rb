class VisitorTrackingJob < ApplicationJob
  queue_as :default

  def perform(page_path, page_title, request_data)
    # Create a mock request object for the service
    mock_request = MockRequest.new(request_data)

    # Track the page view
    VisitorTrackingService.track_page_view(
      mock_request,
      page_path,
      page_title: page_title
    )
  rescue => e
    # Log errors but don't fail the job
    Rails.logger.error "Visitor tracking job failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  # Mock request object to work with VisitorTrackingService
  class MockRequest
    attr_reader :data

    def initialize(data)
      @data = data
      @session = MockSession.new(data[:visitor_id])
      @cookies = MockCookies.new(data[:visitor_id])
    end

    def session
      @session
    end

    def cookies
      @cookies
    end

    def cookie_jar
      @cookies
    end

    def user_agent
      @data[:user_agent]
    end

    def referer
      @data[:referrer]
    end

    def remote_ip
      @data[:ip_address]
    end

    def ip
      @data[:ip_address]
    end

    def headers
      {
        'HTTP_X_FORWARDED_FOR' => @data[:ip_address],
        'HTTP_X_REAL_IP' => @data[:ip_address]
      }
    end

    def path
      # Not used in the service for background jobs
      nil
    end

    def env
      # Return empty env for background jobs
      {}
    end

    def respond_to?(method)
      return true if [:session, :cookies, :cookie_jar, :user_agent, :referer, :remote_ip, :ip, :headers, :path, :env].include?(method)
      super
    end
  end

  class MockSession
    def initialize(visitor_id)
      @data = { visitor_id: visitor_id }
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      @data[key] = value
    end

    def id
      @data[:session_id] || SecureRandom.hex(16)
    end
  end

  class MockCookies
    def initialize(visitor_id)
      @data = { visitor_id: visitor_id }
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
