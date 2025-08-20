# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Only seed in development environment to avoid accidental data creation in production
if Rails.env.development?
  puts "🌱 Seeding development database..."

  # Create sample users
  users = [
    {
      email: "john@example.com",
      password: "password123",
      username: "johndoe",
      full_name: "John Doe",
      bio: "Full-stack developer passionate about Ruby on Rails and modern web technologies. I love building clean, scalable applications that solve real-world problems.",
      github_url: "https://github.com/johndoe",
      linkedin_url: "https://linkedin.com/in/johndoe",
      website_url: "https://johndoe.dev"
    },
    {
      email: "jane@example.com",
      password: "password123",
      username: "janesmith",
      full_name: "Jane Smith",
      bio: "Frontend developer and UI/UX designer. I create beautiful, accessible user experiences with React, Vue, and modern CSS frameworks.",
      github_url: "https://github.com/janesmith",
      linkedin_url: "https://linkedin.com/in/janesmith",
      website_url: "https://janesmith.design"
    },
    {
      email: "alex@example.com",
      password: "password123",
      username: "alexdev",
      full_name: "Alex Rodriguez",
      bio: "Backend engineer specializing in API design and database optimization. Experienced with Rails, PostgreSQL, and cloud infrastructure.",
      github_url: "https://github.com/alexdev",
      linkedin_url: "https://linkedin.com/in/alexrodriguez"
    },
    {
      email: "sarah@example.com",
      password: "password123",
      username: "sarahcode",
      full_name: "Sarah Wilson",
      bio: "Mobile app developer and computer science student. Building the future one app at a time.",
      github_url: "https://github.com/sarahcode"
    },
    {
      email: "demo@example.com",
      password: "password123",
      username: "demouser",
      full_name: "Demo User",
      bio: "This is a demo account for testing purposes."
    }
  ]

  created_users = []

  users.each do |user_attrs|
    user = User.find_or_create_by(email: user_attrs[:email]) do |u|
      u.assign_attributes(user_attrs)
    end

    if user.persisted?
      created_users << user
      puts "✅ Created user: #{user.username} (#{user.email})"
    else
      puts "❌ Failed to create user #{user_attrs[:username]}: #{user.errors.full_messages.join(', ')}"
    end
  end

  # Sample project data
  sample_projects = [
    {
      title: "E-commerce Platform",
      description: "A fully-featured e-commerce platform built with Rails 7, featuring user authentication, product catalog, shopping cart, payment processing with Stripe, order management, and admin dashboard. Includes real-time notifications and responsive design.",
      technologies: "Ruby on Rails, PostgreSQL, Stripe API, Hotwire, Tailwind CSS, Redis, Sidekiq",
      github_url: "https://github.com/johndoe/ecommerce-platform",
      demo_url: "https://ecommerce-demo.herokuapp.com",
      status: "published",
      featured: true
    },
    {
      title: "Task Management App",
      description: "A collaborative task management application inspired by Trello. Features include drag-and-drop kanban boards, team collaboration, real-time updates, file attachments, and deadline tracking.",
      technologies: "Ruby on Rails, PostgreSQL, Action Cable, Stimulus, Tailwind CSS, Active Storage",
      github_url: "https://github.com/johndoe/task-manager",
      demo_url: "https://taskmanager-demo.herokuapp.com",
      status: "published"
    },
    {
      title: "Weather Dashboard",
      description: "A beautiful weather dashboard that displays current conditions and 7-day forecasts for multiple cities. Features geolocation support, favorite locations, and weather alerts.",
      technologies: "React, TypeScript, OpenWeather API, Recharts, Tailwind CSS",
      github_url: "https://github.com/janesmith/weather-dashboard",
      demo_url: "https://weather-dashboard-demo.netlify.app",
      status: "published",
      featured: true
    },
    {
      title: "Portfolio Website",
      description: "A responsive portfolio website showcasing my work and skills. Built with modern web technologies and optimized for performance and accessibility.",
      technologies: "HTML5, CSS3, JavaScript, GSAP, Webpack",
      github_url: "https://github.com/janesmith/portfolio",
      demo_url: "https://janesmith.design",
      status: "published"
    },
    {
      title: "API Gateway Service",
      description: "A high-performance API gateway built with Rails API mode. Handles authentication, rate limiting, request routing, and response caching for microservices architecture.",
      technologies: "Ruby on Rails API, Redis, Docker, PostgreSQL, JWT",
      github_url: "https://github.com/alexdev/api-gateway",
      status: "published"
    },
    {
      title: "Chat Application",
      description: "Real-time chat application with private messages, group chats, file sharing, and emoji reactions. Built with Action Cable for WebSocket connections.",
      technologies: "Ruby on Rails, Action Cable, PostgreSQL, Stimulus, CSS3",
      github_url: "https://github.com/alexdev/chat-app",
      demo_url: "https://chat-demo.herokuapp.com",
      status: "published"
    },
    {
      title: "Fitness Tracker Mobile App",
      description: "Cross-platform mobile app for tracking workouts, nutrition, and fitness goals. Features progress charts, social sharing, and integration with wearable devices.",
      technologies: "React Native, TypeScript, Firebase, Chart.js, Expo",
      github_url: "https://github.com/sarahcode/fitness-tracker",
      status: "published"
    },
    {
      title: "Blog Engine",
      description: "A simple yet powerful blog engine with markdown support, SEO optimization, and comment system. Perfect for developers who want to share their knowledge.",
      technologies: "Ruby on Rails, PostgreSQL, Markdown, Tailwind CSS",
      github_url: "https://github.com/sarahcode/blog-engine",
      status: "draft"
    },
    {
      title: "Learning Management System",
      description: "An educational platform for online courses with video streaming, quizzes, progress tracking, and certificate generation.",
      technologies: "Ruby on Rails, PostgreSQL, Active Storage, Stimulus",
      github_url: "https://github.com/demouser/lms",
      status: "draft"
    }
  ]

  # Assign projects to users
  project_assignments = [
    [ 0, 0 ], [ 0, 1 ], # John gets first 2 projects
    [ 1, 2 ], [ 1, 3 ], # Jane gets next 2 projects
    [ 2, 4 ], [ 2, 5 ], # Alex gets next 2 projects
    [ 3, 6 ], [ 3, 7 ], # Sarah gets next 2 projects
    [ 4, 8 ]          # Demo user gets last project
  ]

  project_assignments.each do |user_index, project_index|
    next unless created_users[user_index] && sample_projects[project_index]

    user = created_users[user_index]
    project_data = sample_projects[project_index]

    project = user.projects.find_or_create_by(title: project_data[:title]) do |p|
      p.assign_attributes(project_data)
    end

    if project.persisted?
      puts "✅ Created project: #{project.title} for #{user.username}"
    else
      puts "❌ Failed to create project #{project_data[:title]}: #{project.errors.full_messages.join(', ')}"
    end
  end

  puts "\n🎉 Seeding completed!"
  puts "\nSample users created:"
  puts "Email: john@example.com | Username: johndoe | Password: password123"
  puts "Email: jane@example.com | Username: janesmith | Password: password123"
  puts "Email: alex@example.com | Username: alexdev | Password: password123"
  puts "Email: sarah@example.com | Username: sarahcode | Password: password123"
  puts "Email: demo@example.com | Username: demouser | Password: password123"
  puts "\nYou can sign in with any of these accounts to explore the application!"

else
  puts "Skipping seeds - not in development environment"
end
