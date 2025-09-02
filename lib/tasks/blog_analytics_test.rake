namespace :blog_analytics do
  desc "Create test blog visitor data and show analytics"
  task test: :environment do
    puts "📚 BLOG ANALYTICS TEST"
    puts "=" * 40

    # Create some blog-specific visitor data
    puts "\n1️⃣ Creating blog visitor test data..."

    # Create visitors who viewed blog content
    5.times do |i|
      visitor_id = SecureRandom.uuid

      visitor = Visitor.create!(
        visitor_id: visitor_id,
        ip_address: "192.168.1.#{100 + i}",
        user_agent: 'Mozilla/5.0 (Test Browser) AppleWebKit/537.36',
        referrer: ['https://google.com', 'https://twitter.com', nil].sample,
        country: ['United States', 'Canada', 'United Kingdom'].sample,
        city: ['New York', 'Toronto', 'London'].sample,
        first_visit_at: (i + 1).days.ago + rand(0..23).hours,
        last_visit_at: (i + 1).days.ago + rand(0..23).hours,
        visit_count: rand(1..3),
        page_views: rand(2..6),
        total_time_on_site: rand(180..1200), # 3-20 minutes
        converted: rand < 0.15 # 15% conversion rate for blog visitors
      )

      # Create blog page views for each visitor
      blog_pages = ['/blog', '/blog/1', '/blog/2', '/blog/3', '/blog/getting-started']

      # Always start with blog index or a specific post
      first_page = ['/blog', '/blog/1', '/blog/getting-started'].sample
      VisitorPageView.create!(
        visitor: visitor,
        page_path: first_page,
        page_title: first_page == '/blog' ? 'Blog Index' : 'Blog Post',
        referrer: visitor.referrer,
        time_on_page: rand(60..300), # 1-5 minutes
        viewed_at: visitor.first_visit_at
      )

      # Add additional blog page views
      (visitor.page_views - 1).times do |j|
        page = blog_pages.sample
        VisitorPageView.create!(
          visitor: visitor,
          page_path: page,
          page_title: page == '/blog' ? 'Blog Index' : 'Blog Post',
          referrer: j == 0 ? first_page : blog_pages.sample,
          time_on_page: rand(30..600), # 30 seconds to 10 minutes
          viewed_at: visitor.first_visit_at + (j + 1).minutes
        )
      end

      # Some visitors also visit other pages
      if rand < 0.3 # 30% chance
        other_pages = ['/', '/projects', '/about']
        VisitorPageView.create!(
          visitor: visitor,
          page_path: other_pages.sample,
          page_title: 'Other Page',
          referrer: blog_pages.sample,
          time_on_page: rand(30..180),
          viewed_at: visitor.first_visit_at + visitor.page_views.minutes
        )
        visitor.increment!(:page_views)
      end
    end

    puts "✅ Created blog visitor test data!"

    # Test blog analytics methods
    puts "\n2️⃣ Testing blog analytics methods..."

    days = 30
    blog_stats = {
      'Blog visitors' => Visitor.blog_visitors(days),
      'Blog page views' => VisitorPageView.blog_page_views(days),
      'Blog unique page views' => VisitorPageView.blog_unique_page_views(days),
      'Blog bounce rate' => "#{Visitor.blog_bounce_rate(days)}%",
      'Blog conversion rate' => "#{Visitor.blog_conversion_rate(days)}%",
      'Average blog time on site' => "#{Visitor.average_blog_time_on_site(days)}m",
      'Blog average time on page' => "#{VisitorPageView.blog_average_time_on_page(days)}s"
    }

    blog_stats.each do |metric, value|
      puts "  #{metric}: #{value}"
    end

    # Test blog content analysis
    puts "\n3️⃣ Blog content performance..."
    content_stats = VisitorPageView.blog_index_vs_posts_views(days)
    puts "  Blog index views: #{content_stats[:index_views]}"
    puts "  Blog post views: #{content_stats[:post_views]}"
    puts "  Index to post ratio: 1:#{content_stats[:index_to_post_ratio]}"

    # Test most popular blog posts
    puts "\n4️⃣ Most popular blog posts..."
    popular_posts = VisitorPageView.most_popular_blog_posts(5, days)
    popular_posts.each_with_index do |(post, views), index|
      puts "  #{index + 1}. #{post}: #{views} views"
    end

    # Test conversion funnel
    puts "\n5️⃣ Blog conversion funnel..."
    funnel = Visitor.blog_to_signup_conversion_funnel(days)
    puts "  Blog viewers: #{funnel[:blog_viewers]}"
    puts "  Explored other pages: #{funnel[:blog_to_other_pages]} (#{funnel[:blog_engagement_rate]}%)"
    puts "  Converted to signup: #{funnel[:blog_to_conversion]} (#{funnel[:blog_conversion_rate]}%)"

    # Test reading patterns
    puts "\n6️⃣ Reading patterns..."
    reading_patterns = VisitorPageView.blog_reading_patterns(days)
    puts "  Average reading time: #{(reading_patterns[:average_reading_time] / 60).round(1)} minutes"
    puts "  Total reading time: #{reading_patterns[:total_reading_time].round(1)} minutes"

    puts "\n  Reading depth distribution:"
    reading_patterns[:reading_depth].each do |depth, count|
      puts "    #{depth}: #{count}"
    end

    puts "\n✨ Blog analytics test completed!"
    puts "\nYou can now view the blog analytics dashboard at /admin/blog_analytics"
  end

  desc "Show current blog analytics summary"
  task summary: :environment do
    puts "\n📚 BLOG ANALYTICS SUMMARY"
    puts "=" * 40

    [7, 30].each do |days|
      puts "\n📅 Last #{days} days:"
      puts "  Blog visitors: #{Visitor.blog_visitors(days)}"
      puts "  Blog page views: #{VisitorPageView.blog_page_views(days)}"
      puts "  Blog bounce rate: #{Visitor.blog_bounce_rate(days)}%"
      puts "  Blog conversion rate: #{Visitor.blog_conversion_rate(days)}%"
      puts "  Average blog time: #{Visitor.average_blog_time_on_site(days)} minutes"
    end

    puts "\n📊 Blog vs Other Content:"
    total_views = VisitorPageView.where("viewed_at > ?", 30.days.ago).count
    blog_views = VisitorPageView.blog_page_views(30)
    blog_percentage = total_views > 0 ? (blog_views.to_f / total_views * 100).round(2) : 0

    puts "  Total page views: #{total_views}"
    puts "  Blog page views: #{blog_views} (#{blog_percentage}%)"
    puts "  Other page views: #{total_views - blog_views}"

    puts "\n🔝 TOP BLOG POSTS:"
    VisitorPageView.most_popular_blog_posts(5, 30).each_with_index do |(post, views), index|
      puts "  #{index + 1}. #{post}: #{views} views"
    end
  end
end
