# Sample visitor data for testing visitor analytics
return unless Rails.env.development?

puts "Creating sample visitor data..."

# Create sample visitors over the last 30 days
30.times do |i|
  date = i.days.ago

  # Create 5-15 visitors per day
  rand(5..15).times do
    visitor_id = SecureRandom.uuid

    visitor = Visitor.create!(
      visitor_id: visitor_id,
      ip_address: "#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}",
      user_agent: [
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
      ].sample,
      referrer: [
        'https://google.com',
        'https://github.com',
        'https://twitter.com',
        'https://linkedin.com',
        nil
      ].sample,
      country: ['United States', 'Canada', 'United Kingdom', 'Germany', 'France', 'Spain', 'Brazil', 'Japan', nil].sample,
      city: ['New York', 'Toronto', 'London', 'Berlin', 'Paris', 'Madrid', 'São Paulo', 'Tokyo', nil].sample,
      first_visit_at: date + rand(0..23).hours + rand(0..59).minutes,
      last_visit_at: date + rand(0..23).hours + rand(0..59).minutes,
      visit_count: rand(1..5),
      page_views: rand(1..10),
      total_time_on_site: rand(30..1800), # 30 seconds to 30 minutes
      converted: rand < 0.05 # 5% conversion rate
    )

    # Create page views for each visitor
    pages = ['/', '/blog', '/projects', '/about', '/contact']
    rand(1..visitor.page_views).times do |j|
      VisitorPageView.create!(
        visitor: visitor,
        page_path: pages.sample,
        page_title: "Page #{j + 1}",
        referrer: j == 0 ? visitor.referrer : pages.sample,
        time_on_page: rand(10..300), # 10 seconds to 5 minutes
        viewed_at: visitor.first_visit_at + j.minutes
      )
    end

    # Link some visitors to existing users (converted visitors)
    if visitor.converted? && User.exists?
      visitor.update!(user: User.order('RANDOM()').first)
    end
  end
end

puts "Created #{Visitor.count} sample visitors with #{VisitorPageView.count} page views"
