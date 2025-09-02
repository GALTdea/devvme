class GeolocationService
  PROVIDERS = {
    ipapi: "http://ip-api.com/json/",
    ipinfo: "https://ipinfo.io/",
    freegeoip: "https://freegeoip.app/json/"
  }.freeze

  def self.lookup(ip_address, provider: :ipapi)
    return default_location if ip_address.blank? || local_ip?(ip_address)

    case provider
    when :ipapi
      lookup_with_ipapi(ip_address)
    when :ipinfo
      lookup_with_ipinfo(ip_address)
    when :freegeoip
      lookup_with_freegeoip(ip_address)
    else
      default_location
    end
  rescue => e
    Rails.logger.error "Geolocation lookup failed: #{e.message}"
    default_location
  end

  private

  def self.lookup_with_ipapi(ip_address)
    url = "#{PROVIDERS[:ipapi]}#{ip_address}?fields=status,country,countryCode,region,regionName,city,lat,lon,timezone"

    response = fetch_with_timeout(url)
    data = JSON.parse(response.body)

    return default_location if data["status"] == "fail"

    {
      country: data["country"],
      country_code: data["countryCode"],
      region: data["regionName"],
      city: data["city"],
      latitude: data["lat"],
      longitude: data["lon"],
      timezone: data["timezone"]
    }
  end

  def self.lookup_with_ipinfo(ip_address)
    # Note: IPinfo requires API token for production use
    token = Rails.application.credentials.dig(:ipinfo, :token)
    url = "#{PROVIDERS[:ipinfo]}#{ip_address}/json"
    url += "?token=#{token}" if token

    response = fetch_with_timeout(url)
    data = JSON.parse(response.body)

    return default_location if data["bogon"] == true

    location = data["loc"]&.split(",") || []

    {
      country: data["country"],
      country_code: data["country"],
      region: data["region"],
      city: data["city"],
      latitude: location[0]&.to_f,
      longitude: location[1]&.to_f,
      timezone: data["timezone"]
    }
  end

  def self.lookup_with_freegeoip(ip_address)
    url = "#{PROVIDERS[:freegeoip]}#{ip_address}"

    response = fetch_with_timeout(url)
    data = JSON.parse(response.body)

    {
      country: data["country_name"],
      country_code: data["country_code"],
      region: data["region_name"],
      city: data["city"],
      latitude: data["latitude"],
      longitude: data["longitude"],
      timezone: data["time_zone"]
    }
  end

  def self.fetch_with_timeout(url, timeout: 5)
    uri = URI(url)

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                   open_timeout: timeout, read_timeout: timeout) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "DevvmeApp/1.0"
      http.request(request)
    end
  end

  def self.local_ip?(ip_address)
    # Check for local/private IP addresses
    local_patterns = [
      /^127\./,           # 127.0.0.0/8 (localhost)
      /^10\./,            # 10.0.0.0/8 (private)
      /^192\.168\./,      # 192.168.0.0/16 (private)
      /^172\.(1[6-9]|2[0-9]|3[0-1])\./,  # 172.16.0.0/12 (private)
      /^169\.254\./,      # 169.254.0.0/16 (link-local)
      /^::1$/,            # IPv6 localhost
      /^fe80:/i           # IPv6 link-local
    ]

    local_patterns.any? { |pattern| ip_address.match?(pattern) }
  end

  def self.default_location
    {
      country: nil,
      country_code: nil,
      region: nil,
      city: nil,
      latitude: nil,
      longitude: nil,
      timezone: nil
    }
  end
end
