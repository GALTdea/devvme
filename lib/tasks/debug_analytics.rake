namespace :analytics do
  desc "Debug visitor analytics dashboard data"
  task debug: :environment do
    puts "🔍 DEBUGGING VISITOR ANALYTICS DASHBOARD"
    puts "=" * 50

    # Simulate the controller logic
    time_range = "30_days"
    days = 30

    puts "\n📊 Dashboard Metrics (#{time_range}):"
    puts "-" * 30

    visitor_stats = {
      total_visitors: Visitor.total_visitors,
      unique_visitors: Visitor.unique_visitors(days),
      returning_visitors: Visitor.returning_visitors(days),
      conversion_rate: Visitor.conversion_rate(days),
      average_time_on_site: Visitor.average_time_on_site(days),
      average_page_views: Visitor.average_page_views(days)
    }

    visitor_stats.each do |key, value|
      puts "  #{key.to_s.humanize}: #{value}#{'%' if key == :conversion_rate}#{'m' if key == :average_time_on_site}"
    end

    page_view_stats = {
      total_page_views: VisitorPageView.total_page_views(days),
      unique_page_views: VisitorPageView.unique_page_views(days),
      average_time_on_page: VisitorPageView.average_time_on_page(days)
    }

    puts "\n📄 Page View Stats:"
    puts "-" * 20
    page_view_stats.each do |key, value|
      puts "  #{key.to_s.humanize}: #{value}"
    end

    puts "\n📈 Chart Data:"
    puts "-" * 15
    visitors_by_date = Visitor.visitors_by_date(days)
    page_views_by_date = VisitorPageView.page_views_by_date(days)

    puts "  Visitors by date (sample):"
    visitors_by_date.to_a.last(5).each do |date, count|
      puts "    #{date}: #{count} visitors"
    end

    puts "  Page views by date (sample):"
    page_views_by_date.to_a.last(5).each do |date, count|
      puts "    #{date}: #{count} views"
    end

    puts "\n🔝 Top Data:"
    puts "-" * 10

    top_pages = VisitorPageView.top_pages(5, days)
    puts "  Top pages:"
    top_pages.each_with_index do |(page, views), index|
      puts "    #{index + 1}. #{page}: #{views}"
    end

    top_referrers = Visitor.top_referrers(5, days)
    puts "  Top referrers:"
    if top_referrers.any?
      top_referrers.each_with_index do |(referrer, count), index|
        puts "    #{index + 1}. #{referrer}: #{count}"
      end
    else
      puts "    No referrer data"
    end

    visitors_by_country = Visitor.visitors_by_country(5, days)
    puts "  Visitors by country:"
    visitors_by_country.each_with_index do |(country, count), index|
      puts "    #{index + 1}. #{country || 'Unknown'}: #{count}"
    end

    puts "\n✨ Debug complete! Your analytics should show this data."
  end
end
