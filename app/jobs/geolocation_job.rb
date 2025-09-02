class GeolocationJob < ApplicationJob
  queue_as :default

  def perform(visitor_id, ip_address)
    visitor = Visitor.find_by(id: visitor_id)
    return unless visitor

    # Skip if location already exists
    return if visitor.country.present? || visitor.city.present?

    # Lookup geolocation data
    location_data = GeolocationService.lookup(ip_address)

    # Update visitor with location data
    visitor.update!(
      country: location_data[:country],
      city: location_data[:city]
    )
  rescue => e
    Rails.logger.error "Geolocation job failed for visitor #{visitor_id}: #{e.message}"
  end
end
