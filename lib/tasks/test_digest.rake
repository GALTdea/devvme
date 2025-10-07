namespace :digest do
  desc "Test digest email generation and delivery"
  task test: :environment do
    puts "🧪 Testing Digest Email System..."
    puts "=" * 60

    # Get or create test users
    user1 = User.find_by(username: "john") || User.first
    user2 = User.find_by(username: "jane") || User.second

    if user1.nil?
      puts "❌ No users found. Please create users first."
      exit
    end

    puts "\n📧 Test Setup:"
    puts "  Recipient: #{user1.display_name} (@#{user1.username})"
    puts "  Email: #{user1.email}"

    if user2
      puts "  Content from: #{user2.display_name} (@#{user2.username})"

      # Create test content if user2 exists
      unless user1.following?(user2)
        user1.follow!(user2)
        puts "  ✓ Made #{user1.username} follow #{user2.username}"
      end

      # Create a test blog post if user2 doesn't have recent ones
      if user2.blog_posts.where('created_at > ?', 1.week.ago).empty?
        blog_post = user2.blog_posts.create!(
          title: "Test Blog Post for Digest - #{Time.current.to_i}",
          content: "This is a test blog post to demonstrate the digest email system. Lorem ipsum dolor sit amet.",
          excerpt: "A test blog post for digest email testing.",
          published: true,
          published_at: Time.current
        )
        puts "  ✓ Created test blog post: #{blog_post.title}"
      end
    end

    puts "\n📊 Generating digest content..."
    digest_data = DigestGeneratorService.generate_digest_for_user(user1)

    if digest_data.empty?
      puts "  ⚠️  No content found. User might not be following anyone with recent content."
      puts "  Creating sample content..."

      # Ensure user1 has a digest preference
      user1.digest_preference_or_create

      digest_data = {
        "sample_user" => {
          user: user2 || user1,
          blog_posts: [],
          projects: [],
          profile_updates: []
        }
      }
    end

    puts "  ✓ Found content from #{digest_data.keys.count} user(s)"
    digest_data.each do |username, content|
      puts "    - #{username}: #{content[:blog_posts].count} posts, #{content[:projects].count} projects"
    end

    puts "\n📮 Sending digest email..."
    UserDigestMailer.weekly_digest(user1, digest_data).deliver_now

    puts "\n✅ Success! Email sent to #{user1.email}"
    puts "📬 Check your browser - letter_opener should have opened the email"
    puts "   Or check: tmp/letter_opener/"
    puts "\n💡 Tip: The email includes:"
    puts "   - Content from users you follow"
    puts "   - Links to manage preferences"
    puts "   - Unsubscribe option"
    puts "=" * 60
  end

  desc "Create test follow data for digest testing"
  task create_test_data: :environment do
    puts "🔧 Creating test data for digest testing..."

    # Get first two users
    user1 = User.first
    user2 = User.second

    if user1.nil? || user2.nil?
      puts "❌ Need at least 2 users. Please create users first."
      exit
    end

    # Make user1 follow user2
    user1.follow!(user2) unless user1.following?(user2)
    puts "✓ #{user1.username} is now following #{user2.username}"

    # Create test blog post for user2
    blog_post = user2.blog_posts.create!(
      title: "Amazing Tutorial on Rails - #{Time.current.to_i}",
      content: "This is an amazing tutorial about Ruby on Rails. Learn how to build web applications with Rails 8!",
      excerpt: "Learn Rails 8 with this comprehensive tutorial.",
      published: true,
      published_at: Time.current
    )
    puts "✓ Created blog post: #{blog_post.title}"

    # Create test project for user2
    project = user2.projects.create!(
      title: "Awesome Rails App - #{Time.current.to_i}",
      description: "A full-featured Rails application with Hotwire and Tailwind CSS.",
      status: :published,
      technologies_used: ["Ruby on Rails", "PostgreSQL", "Hotwire"],
      display_order: user2.projects.count + 1
    )
    puts "✓ Created project: #{project.title}"

    # Ensure digest preferences exist
    user1.digest_preference_or_create
    user2.digest_preference_or_create

    puts "\n✅ Test data created successfully!"
    puts "   Now run: bin/rails digest:test"
  end

  desc "Send digest to specific user"
  task :send_to_user, [:username] => :environment do |t, args|
    username = args[:username] || ENV['USERNAME']

    if username.blank?
      puts "❌ Please provide a username:"
      puts "   bin/rails digest:send_to_user[username]"
      puts "   or"
      puts "   USERNAME=john bin/rails digest:send_to_user"
      exit
    end

    user = User.find_by(username: username)

    if user.nil?
      puts "❌ User '#{username}' not found"
      exit
    end

    puts "📮 Sending digest to #{user.display_name} (#{user.email})..."

    digest_data = DigestGeneratorService.generate_digest_for_user(user)
    UserDigestMailer.weekly_digest(user, digest_data).deliver_now

    puts "✅ Digest sent! Check your browser."
  end
end
