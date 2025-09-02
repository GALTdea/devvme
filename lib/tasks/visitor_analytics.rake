namespace :visitor_analytics do
  desc "Create test visitors for current time period"
  task create_test_data: :environment do
    puts "Creating test visitor data for the current time period..."

    # Create visitors for the last 7 days
    7.times do |i|
      date = i.days.ago

      # Create 2-5 visitors per day
      rand(2..5).times do
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
            nil
          ].sample,
          country: ['United States', 'Canada', 'United Kingdom', 'Germany', nil].sample,
          city: ['New York', 'Toronto', 'London', 'Berlin', nil].sample,
          first_visit_at: date + rand(0..23).hours + rand(0..59).minutes,
          last_visit_at: date + rand(0..23).hours + rand(0..59).minutes,
          visit_count: rand(1..3),
          page_views: rand(1..5),
          total_time_on_site: rand(30..600), # 30 seconds to 10 minutes
          converted: rand < 0.1 # 10% conversion rate
        )

        # Create page views for each visitor
        pages = ['/', '/blog', '/projects', '/about']
        rand(1..visitor.page_views).times do |j|
          VisitorPageView.create!(
            visitor: visitor,
            page_path: pages.sample,
            page_title: "Page #{j + 1}",
            referrer: j == 0 ? visitor.referrer : pages.sample,
            time_on_page: rand(10..120), # 10 seconds to 2 minutes
            viewed_at: visitor.first_visit_at + j.minutes
          )
        end
      end
    end

    puts "✅ Created test visitor data!"
    puts "Total visitors: #{Visitor.count}"
    puts "Total page views: #{VisitorPageView.count}"
    puts "Recent visitors (last 7 days): #{Visitor.where('first_visit_at > ?', 7.days.ago).count}"
  end

  desc "Show current visitor analytics summary"
  task summary: :environment do
    puts "\n📊 VISITOR ANALYTICS SUMMARY"
    puts "=" * 40

    [7, 30].each do |days|
      puts "\n📅 Last #{days} days:"
      puts "  Total visitors: #{Visitor.total_visitors}"
      puts "  Unique visitors: #{Visitor.unique_visitors(days)}"
      puts "  Returning visitors: #{Visitor.returning_visitors(days)}"
      puts "  Conversion rate: #{Visitor.conversion_rate(days)}%"
      puts "  Avg time on site: #{Visitor.average_time_on_site(days)} minutes"
      puts "  Avg page views: #{Visitor.average_page_views(days)}"
      puts "  Total page views: #{VisitorPageView.total_page_views(days)}"
    end

    puts "\n🔝 TOP PAGES (last 30 days):"
    VisitorPageView.top_pages(5, 30).each_with_index do |(page, views), index|
      puts "  #{index + 1}. #{page}: #{views} views"
    end

    puts "\n🌍 TOP COUNTRIES (last 30 days):"
    Visitor.visitors_by_country(5, 30).each_with_index do |(country, count), index|
      puts "  #{index + 1}. #{country || 'Unknown'}: #{count} visitors"
    end

    puts "\n📈 RECENT ACTIVITY:"
    recent = Visitor.recent.limit(3)
    if recent.any?
      recent.each do |visitor|
        puts "  • Visitor #{visitor.visitor_id[0..8]}... - #{visitor.page_views} pages - #{time_ago_in_words(visitor.last_visit_at)} ago"
      end
    else
      puts "  No recent visitors"
    end
  end

  private

  def time_ago_in_words(time)
    distance = Time.current - time
    case distance
    when 0..59
      "#{distance.to_i} seconds"
    when 60..3599
      "#{(distance / 60).to_i} minutes"
    when 3600..86399
      "#{(distance / 3600).to_i} hours"
    else
      "#{(distance / 86400).to_i} days"
    end
  end
end
