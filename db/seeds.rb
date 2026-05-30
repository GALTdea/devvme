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
      technologies_used: ["Ruby on Rails", "PostgreSQL", "Stripe API", "Hotwire", "Tailwind CSS", "Redis", "Sidekiq"],
      github_url: "https://github.com/johndoe/ecommerce-platform",
      demo_url: "https://ecommerce-demo.herokuapp.com",
      status: "published",
      featured: true
    },
    {
      title: "Task Management App",
      description: "A collaborative task management application inspired by Trello. Features include drag-and-drop kanban boards, team collaboration, real-time updates, file attachments, and deadline tracking.",
      technologies_used: ["Ruby on Rails", "PostgreSQL", "Action Cable", "Stimulus", "Tailwind CSS", "Active Storage"],
      github_url: "https://github.com/johndoe/task-manager",
      demo_url: "https://taskmanager-demo.herokuapp.com",
      status: "published"
    },
    {
      title: "Weather Dashboard",
      description: "A beautiful weather dashboard that displays current conditions and 7-day forecasts for multiple cities. Features geolocation support, favorite locations, and weather alerts.",
      technologies_used: ["React", "TypeScript", "OpenWeather API", "Recharts", "Tailwind CSS"],
      github_url: "https://github.com/janesmith/weather-dashboard",
      demo_url: "https://weather-dashboard-demo.netlify.app",
      status: "published",
      featured: true
    },
    {
      title: "Portfolio Website",
      description: "A responsive portfolio website showcasing my work and skills. Built with modern web technologies and optimized for performance and accessibility.",
      technologies_used: ["HTML5", "CSS3", "JavaScript", "GSAP", "Webpack"],
      github_url: "https://github.com/janesmith/portfolio",
      demo_url: "https://janesmith.design",
      status: "published"
    },
    {
      title: "API Gateway Service",
      description: "A high-performance API gateway built with Rails API mode. Handles authentication, rate limiting, request routing, and response caching for microservices architecture.",
      technologies_used: ["Ruby on Rails API", "Redis", "Docker", "PostgreSQL", "JWT"],
      github_url: "https://github.com/alexdev/api-gateway",
      status: "published"
    },
    {
      title: "Chat Application",
      description: "Real-time chat application with private messages, group chats, file sharing, and emoji reactions. Built with Action Cable for WebSocket connections.",
      technologies_used: ["Ruby on Rails", "Action Cable", "PostgreSQL", "Stimulus", "CSS3"],
      github_url: "https://github.com/alexdev/chat-app",
      demo_url: "https://chat-demo.herokuapp.com",
      status: "published"
    },
    {
      title: "Fitness Tracker Mobile App",
      description: "Cross-platform mobile app for tracking workouts, nutrition, and fitness goals. Features progress charts, social sharing, and integration with wearable devices.",
      technologies_used: ["React Native", "TypeScript", "Firebase", "Chart.js", "Expo"],
      github_url: "https://github.com/sarahcode/fitness-tracker",
      status: "published"
    },
    {
      title: "Blog Engine",
      description: "A simple yet powerful blog engine with markdown support, SEO optimization, and comment system. Perfect for developers who want to share their knowledge.",
      technologies_used: ["Ruby on Rails", "PostgreSQL", "Markdown", "Tailwind CSS"],
      github_url: "https://github.com/sarahcode/blog-engine",
      status: "draft"
    },
    {
      title: "Learning Management System",
      description: "An educational platform for online courses with video streaming, quizzes, progress tracking, and certificate generation.",
      technologies_used: ["Ruby on Rails", "PostgreSQL", "Active Storage", "Stimulus"],
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

  # Sample blog posts data
  sample_blog_posts = [
    {
      title: "Building Scalable Rails Applications: Best Practices and Patterns",
      content: <<~MARKDOWN,
        # Building Scalable Rails Applications: Best Practices and Patterns

        As applications grow, maintaining clean, scalable code becomes increasingly important. Here are some key patterns and practices I've learned while building large Rails applications.

        ## Service Objects for Complex Business Logic

        Service objects help keep controllers thin and models focused. Here's a simple example:

        ```ruby
        class OrderProcessingService
          def initialize(order)
            @order = order
          end

          def call
            return false unless valid_order?

            process_payment
            update_inventory
            send_confirmation_email

            true
          end

          private

          def valid_order?
            @order.valid? && @order.items.any?
          end

          def process_payment
            # Payment processing logic
          end

          def update_inventory
            # Inventory management logic
          end

          def send_confirmation_email
            # Email notification logic
          end
        end
        ```

        ## Database Optimization Strategies

        Performance is crucial for scalable applications. Some key strategies:

        - **Proper indexing**: Always index foreign keys and frequently queried columns
        - **N+1 query prevention**: Use `includes` and `joins` strategically
        - **Database-level constraints**: Ensure data integrity at the database level
        - **Connection pooling**: Configure appropriate pool sizes for your load

        ## Caching for Performance

        Rails provides excellent caching mechanisms:

        ```ruby
        # Fragment caching
        <% cache @product do %>
          <%= render @product %>
        <% end %>

        # Russian Doll caching
        <% cache [@product, @product.reviews] do %>
          <%= render @product.reviews %>
        <% end %>
        ```

        ## Background Jobs for Heavy Operations

        Use background jobs for time-consuming operations:

        ```ruby
        class ReportGenerationJob < ApplicationJob
          queue_as :default

          def perform(user_id, report_type)
            user = User.find(user_id)
            report = ReportService.new(user, report_type).generate
            ReportMailer.send_report(user, report).deliver_now
          end
        end
        ```

        These patterns have helped me build maintainable, scalable Rails applications that can handle growth gracefully.
      MARKDOWN
      excerpt: "Learn essential patterns and practices for building scalable Rails applications that can handle growth gracefully.",
      published: true,
      published_at: 2.weeks.ago
    },
    {
      title: "Modern Frontend Development with Hotwire and Stimulus",
      content: <<~MARKDOWN,
        # Modern Frontend Development with Hotwire and Stimulus

        Hotwire has revolutionized how we build interactive web applications with Rails. Let's explore how to create modern, SPA-like experiences without complex JavaScript frameworks.

        ## What is Hotwire?

        Hotwire consists of three main components:
        - **Turbo Drive**: Accelerates navigation
        - **Turbo Frames**: Partial page updates
        - **Turbo Streams**: Real-time updates over WebSockets

        ## Building Interactive Components with Stimulus

        Stimulus controllers provide the perfect amount of JavaScript for Rails applications:

        ```javascript
        // app/javascript/controllers/dropdown_controller.js
        import { Controller } from "@hotwire/stimulus"

        export default class extends Controller {
          static targets = ["menu"]

          toggle() {
            this.menuTarget.classList.toggle("hidden")
          }

          hide(event) {
            if (!this.element.contains(event.target)) {
              this.menuTarget.classList.add("hidden")
            }
          }
        }
        ```

        ```erb
        <div data-controller="dropdown" data-action="click@window->dropdown#hide">
          <button data-action="dropdown#toggle">Menu</button>
          <div data-dropdown-target="menu" class="hidden">
            <!-- Menu items -->
          </div>
        </div>
        ```

        ## Turbo Frames for Seamless Navigation

        Turbo Frames allow you to update specific parts of the page:

        ```erb
        <%= turbo_frame_tag "modal" do %>
          <%= link_to "Edit Profile", edit_user_path(current_user),
                      data: { turbo_frame: "modal" } %>
        <% end %>
        ```

        The edit form can then target the same frame for seamless updates.

        ## Real-time Features with Turbo Streams

        Add real-time functionality without JavaScript:

        ```ruby
        # In your controller
        def create
          @comment = @post.comments.build(comment_params)

          if @comment.save
            respond_to do |format|
              format.turbo_stream
              format.html { redirect_to @post }
            end
          end
        end
        ```

        ```erb
        <!-- create.turbo_stream.erb -->
        <%= turbo_stream.append "comments" do %>
          <%= render @comment %>
        <% end %>
        ```

        Hotwire makes it possible to build rich, interactive applications while staying within the Rails paradigm.
      MARKDOWN
      excerpt: "Discover how Hotwire and Stimulus enable modern, interactive frontend development in Rails applications.",
      published: true,
      published_at: 10.days.ago
    },
    {
      title: "Designing Beautiful UIs with Tailwind CSS and Flowbite",
      content: <<~MARKDOWN,
        # Designing Beautiful UIs with Tailwind CSS and Flowbite

        Creating beautiful, consistent user interfaces is crucial for modern web applications. Tailwind CSS and Flowbite provide the perfect combination of utility and components.

        ## Why Tailwind CSS?

        Tailwind's utility-first approach offers several advantages:
        - **Rapid prototyping**: Build interfaces quickly with utility classes
        - **Consistent spacing**: Predefined spacing scale ensures visual harmony
        - **Responsive design**: Mobile-first responsive utilities
        - **Customization**: Easy theming and customization

        ## Component Libraries: Enter Flowbite

        While utilities are powerful, component libraries save time:

        ```html
        <!-- Flowbite Card Component -->
        <div class="max-w-sm bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700">
          <a href="#">
            <img class="rounded-t-lg" src="/docs/images/blog/image-1.jpg" alt="" />
          </a>
          <div class="p-5">
            <a href="#">
              <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
                Noteworthy technology acquisitions 2021
              </h5>
            </a>
            <p class="mb-3 font-normal text-gray-700 dark:text-gray-400">
              Here are the biggest enterprise technology acquisitions of 2021 so far.
            </p>
          </div>
        </div>
        ```

        ## Design System Principles

        Building a cohesive design system:

        1. **Color Palette**: Define primary, secondary, and accent colors
        2. **Typography Scale**: Consistent heading and body text sizes
        3. **Spacing System**: Use consistent margins and padding
        4. **Component Variants**: Create reusable component variations

        ## Dark Mode Support

        Modern applications need dark mode:

        ```html
        <div class="bg-white dark:bg-gray-800 text-gray-900 dark:text-white">
          <h1 class="text-2xl font-bold">Welcome</h1>
          <p class="text-gray-600 dark:text-gray-300">
            This content adapts to dark mode automatically.
          </p>
        </div>
        ```

        ## Accessibility Considerations

        Always design with accessibility in mind:
        - Use semantic HTML elements
        - Ensure sufficient color contrast
        - Provide focus indicators
        - Use ARIA labels when necessary

        The combination of Tailwind CSS and Flowbite enables rapid development of beautiful, accessible user interfaces.
      MARKDOWN
      excerpt: "Learn how to create stunning, accessible user interfaces using Tailwind CSS and Flowbite components.",
      published: true,
      published_at: 1.week.ago
    },
    {
      title: "API Design Principles: Building RESTful Services",
      content: <<~MARKDOWN,
        # API Design Principles: Building RESTful Services

        Well-designed APIs are the backbone of modern applications. Here are key principles for creating maintainable, scalable RESTful services.

        ## REST Fundamentals

        REST (Representational State Transfer) provides a standard for designing web APIs:

        - **Resources**: Everything is a resource with a unique identifier
        - **HTTP Methods**: Use appropriate methods for different operations
        - **Stateless**: Each request contains all necessary information
        - **Uniform Interface**: Consistent resource representation

        ## Resource Design

        Design your resources thoughtfully:

        ```
        GET    /api/v1/users          # List users
        POST   /api/v1/users          # Create user
        GET    /api/v1/users/:id      # Show user
        PUT    /api/v1/users/:id      # Update user (full)
        PATCH  /api/v1/users/:id      # Update user (partial)
        DELETE /api/v1/users/:id      # Delete user
        ```

        ## Nested Resources

        Handle relationships appropriately:

        ```
        GET    /api/v1/users/:user_id/posts     # User's posts
        POST   /api/v1/users/:user_id/posts     # Create post for user
        GET    /api/v1/posts/:id                # Show specific post
        ```

        ## Response Format Consistency

        Maintain consistent response formats:

        ```json
        {
          "data": {
            "id": 1,
            "type": "user",
            "attributes": {
              "email": "john@example.com",
              "username": "johndoe"
            }
          },
          "meta": {
            "timestamp": "2024-01-15T10:30:00Z"
          }
        }
        ```

        ## Error Handling

        Provide meaningful error responses:

        ```json
        {
          "errors": [
            {
              "status": "422",
              "title": "Validation Error",
              "detail": "Email has already been taken",
              "source": { "pointer": "/data/attributes/email" }
            }
          ]
        }
        ```

        ## Authentication and Authorization

        Secure your APIs properly:

        ```ruby
        class ApplicationController < ActionController::API
          before_action :authenticate_user!

          private

          def authenticate_user!
            token = request.headers['Authorization']&.split(' ')&.last
            @current_user = User.find_by_auth_token(token)

            render json: { error: 'Unauthorized' }, status: 401 unless @current_user
          end
        end
        ```

        ## Rate Limiting

        Protect your API from abuse:

        ```ruby
        class ApiController < ApplicationController
          include ActionController::RequestForgeryProtection

          before_action :check_rate_limit

          private

          def check_rate_limit
            # Implement rate limiting logic
          end
        end
        ```

        Following these principles ensures your APIs are intuitive, maintainable, and scalable.
      MARKDOWN
      excerpt: "Master the principles of RESTful API design for building maintainable and scalable web services.",
      published: true,
      published_at: 5.days.ago
    },
    {
      title: "Mobile App Development with React Native: A Developer's Journey",
      content: <<~MARKDOWN,
        # Mobile App Development with React Native: A Developer's Journey

        Transitioning from web development to mobile app development can be challenging, but React Native makes it accessible for JavaScript developers.

        ## Why React Native?

        React Native offers several compelling advantages:

        - **Code Reusability**: Share code between iOS and Android
        - **Faster Development**: Hot reloading and familiar React patterns
        - **Native Performance**: Direct access to native APIs
        - **Large Community**: Extensive ecosystem and third-party libraries

        ## Setting Up Your Development Environment

        Getting started with React Native:

        ```bash
        # Install React Native CLI
        npm install -g react-native-cli

        # Create a new project
        react-native init MyApp

        # Run on iOS
        cd MyApp && react-native run-ios

        # Run on Android
        react-native run-android
        ```

        ## Core Components

        React Native provides essential components out of the box:

        ```jsx
        import React from 'react';
        import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';

        const WelcomeScreen = () => {
          return (
            <View style={styles.container}>
              <Text style={styles.title}>Welcome to My App</Text>
              <TouchableOpacity style={styles.button}>
                <Text style={styles.buttonText}>Get Started</Text>
              </TouchableOpacity>
            </View>
          );
        };

        const styles = StyleSheet.create({
          container: {
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            backgroundColor: '#f5f5f5',
          },
          title: {
            fontSize: 24,
            fontWeight: 'bold',
            marginBottom: 20,
          },
          button: {
            backgroundColor: '#007AFF',
            paddingHorizontal: 20,
            paddingVertical: 10,
            borderRadius: 8,
          },
          buttonText: {
            color: 'white',
            fontWeight: 'bold',
          },
        });
        ```

        ## Navigation

        React Navigation is the standard for navigation:

        ```jsx
        import { NavigationContainer } from '@react-navigation/native';
        import { createStackNavigator } from '@react-navigation/stack';

        const Stack = createStackNavigator();

        export default function App() {
          return (
            <NavigationContainer>
              <Stack.Navigator>
                <Stack.Screen name="Home" component={HomeScreen} />
                <Stack.Screen name="Details" component={DetailsScreen} />
              </Stack.Navigator>
            </NavigationContainer>
          );
        }
        ```

        ## State Management

        For complex apps, consider Redux or Context API:

        ```jsx
        import { createContext, useContext, useReducer } from 'react';

        const AppContext = createContext();

        export const useAppContext = () => {
          const context = useContext(AppContext);
          if (!context) {
            throw new Error('useAppContext must be used within AppProvider');
          }
          return context;
        };
        ```

        ## Performance Optimization

        Key performance considerations:

        1. **Use FlatList for large lists**: Virtualized rendering
        2. **Optimize images**: Use proper sizing and formats
        3. **Minimize re-renders**: Use React.memo and useMemo
        4. **Profile your app**: Use Flipper for debugging

        React Native has made mobile development accessible to web developers, enabling rapid cross-platform app development.
      MARKDOWN
      excerpt: "Explore the journey from web to mobile development using React Native and learn essential patterns for building cross-platform apps.",
      published: true,
      published_at: 3.days.ago
    },
    {
      title: "Database Optimization Techniques for High-Performance Applications",
      content: <<~MARKDOWN,
        # Database Optimization Techniques for High-Performance Applications

        Database performance is crucial for application scalability. Here are proven techniques for optimizing PostgreSQL databases in Rails applications.

        ## Understanding Query Performance

        Start with the basics of query analysis:

        ```sql
        -- Analyze query performance
        EXPLAIN ANALYZE SELECT * FROM users
        WHERE created_at > '2024-01-01'
        ORDER BY email;
        ```

        The EXPLAIN ANALYZE output shows:
        - Execution time
        - Number of rows processed
        - Index usage
        - Join strategies

        ## Indexing Strategies

        Proper indexing is fundamental:

        ```ruby
        # Single column index
        add_index :users, :email

        # Composite index
        add_index :blog_posts, [:user_id, :published, :created_at]

        # Partial index
        add_index :blog_posts, :user_id, where: "published = true"

        # Unique index
        add_index :users, :username, unique: true
        ```

        ## N+1 Query Prevention

        Eliminate N+1 queries with proper eager loading:

        ```ruby
        # Bad: N+1 query
        @users = User.all
        @users.each { |user| puts user.posts.count }

        # Good: Eager loading
        @users = User.includes(:posts)
        @users.each { |user| puts user.posts.count }

        # Even better: Counter cache
        class User < ApplicationRecord
          has_many :posts
        end

        class Post < ApplicationRecord
          belongs_to :user, counter_cache: true
        end
        ```

        ## Query Optimization Techniques

        Optimize your ActiveRecord queries:

        ```ruby
        # Use select to limit columns
        User.select(:id, :email, :username).where(active: true)

        # Use pluck for single values
        User.where(active: true).pluck(:email)

        # Use exists? instead of any?
        User.where(active: true).exists?

        # Use find_each for large datasets
        User.find_each(batch_size: 1000) do |user|
          # Process user
        end
        ```

        ## Database Connection Optimization

        Configure your connection pool properly:

        ```yaml
        # config/database.yml
        production:
          pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
          timeout: 5000
          checkout_timeout: 10
        ```

        ## Caching Strategies

        Implement multiple levels of caching:

        ```ruby
        # Query caching (automatic in Rails)
        Rails.cache.fetch("user_\#{user.id}", expires_in: 1.hour) do
          expensive_user_calculation(user)
        end

        # Counter caching
        class User < ApplicationRecord
          has_many :posts, counter_cache: true
        end

        # Fragment caching in views
        <% cache @user do %>
          <%= render @user %>
        <% end %>
        ```

        ## Monitoring and Maintenance

        Keep your database healthy:

        ```sql
        -- Check table sizes
        SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

        -- Analyze table statistics
        ANALYZE;

        -- Vacuum to reclaim space
        VACUUM ANALYZE;
        ```

        Regular database maintenance and monitoring ensure consistent performance as your application scales.
      MARKDOWN
      excerpt: "Learn essential database optimization techniques to ensure your Rails applications perform well at scale.",
      published: true,
      published_at: 1.day.ago
    },
    {
      title: "Getting Started with TypeScript: A Practical Guide",
      content: <<~MARKDOWN,
        # Getting Started with TypeScript: A Practical Guide

        TypeScript brings static typing to JavaScript, making code more reliable and maintainable. Here's a practical introduction for JavaScript developers.

        ## Why TypeScript?

        TypeScript offers several benefits over vanilla JavaScript:

        - **Type Safety**: Catch errors at compile time
        - **Better IDE Support**: Enhanced autocomplete and refactoring
        - **Self-Documenting Code**: Types serve as documentation
        - **Gradual Adoption**: Can be added incrementally to existing projects

        ## Basic Types

        TypeScript provides several built-in types:

        ```typescript
        // Primitive types
        let name: string = "John";
        let age: number = 30;
        let isActive: boolean = true;

        // Arrays
        let numbers: number[] = [1, 2, 3];
        let names: Array<string> = ["John", "Jane"];

        // Objects
        interface User {
          id: number;
          name: string;
          email?: string; // Optional property
        }

        let user: User = {
          id: 1,
          name: "John Doe"
        };
        ```

        ## Functions and Methods

        Type your functions for better clarity:

        ```typescript
        // Function with typed parameters and return type
        function calculateTotal(price: number, tax: number): number {
          return price * (1 + tax);
        }

        // Arrow function
        const greetUser = (name: string): string => {
          return `Hello, ${name}!`;
        };

        // Optional parameters
        function createUser(name: string, email?: string): User {
          return {
            id: Math.random(),
            name,
            ...(email && { email })
          };
        }
        ```

        ## Interfaces and Types

        Define contracts for your objects:

        ```typescript
        // Interface
        interface Product {
          id: number;
          name: string;
          price: number;
          category: string;
        }

        // Type alias
        type Status = "pending" | "approved" | "rejected";

        // Extending interfaces
        interface DigitalProduct extends Product {
          downloadUrl: string;
          fileSize: number;
        }
        ```

        ## Generics

        Create reusable, type-safe components:

        ```typescript
        // Generic function
        function getFirstItem<T>(items: T[]): T | undefined {
          return items[0];
        }

        const firstNumber = getFirstItem([1, 2, 3]); // number | undefined
        const firstName = getFirstItem(["John", "Jane"]); // string | undefined

        // Generic interface
        interface ApiResponse<T> {
          data: T;
          status: number;
          message: string;
        }

        type UserResponse = ApiResponse<User>;
        type ProductResponse = ApiResponse<Product[]>;
        ```

        ## Working with React

        TypeScript shines in React applications:

        ```typescript
        import React from 'react';

        interface Props {
          title: string;
          count: number;
          onIncrement: () => void;
        }

        const Counter: React.FC<Props> = ({ title, count, onIncrement }) => {
          return (
            <div>
              <h2>{title}</h2>
              <p>Count: {count}</p>
              <button onClick={onIncrement}>Increment</button>
            </div>
          );
        };
        ```

        ## Migration Strategy

        Gradually adopt TypeScript in existing projects:

        1. **Start with `.ts` files**: Begin with new files
        2. **Add type annotations**: Gradually add types to existing code
        3. **Enable strict mode**: Increase type checking as you progress
        4. **Use `any` sparingly**: Avoid `any` type when possible

        TypeScript's gradual typing system makes it easy to adopt incrementally while immediately providing benefits in code quality and developer experience.
      MARKDOWN
      excerpt: "A comprehensive guide to getting started with TypeScript, covering essential concepts and practical examples.",
      published: false,
      published_at: nil
    },
    {
      title: "Building Modern Learning Management Systems",
      content: <<~MARKDOWN,
        # Building Modern Learning Management Systems

        Educational technology is evolving rapidly. Here's how to build a modern, scalable learning management system that meets today's educational needs.

        ## Core Features of Modern LMS

        A comprehensive LMS should include:

        - **Course Management**: Create and organize learning content
        - **User Management**: Students, instructors, and administrators
        - **Assessment Tools**: Quizzes, assignments, and grading
        - **Communication**: Forums, messaging, and announcements
        - **Progress Tracking**: Analytics and reporting
        - **Mobile Support**: Responsive design and mobile apps

        ## Architecture Considerations

        Design for scalability and maintainability:

        ```ruby
        # Course structure
        class Course < ApplicationRecord
          has_many :enrollments
          has_many :students, through: :enrollments
          has_many :lessons, -> { order(:position) }
          has_many :assignments
          belongs_to :instructor, class_name: 'User'
        end

        class Lesson < ApplicationRecord
          belongs_to :course
          has_many :lesson_completions
          has_rich_text :content
        end

        class Enrollment < ApplicationRecord
          belongs_to :student, class_name: 'User'
          belongs_to :course

          enum status: { active: 0, completed: 1, dropped: 2 }
        end
        ```

        ## Video Content Management

        Handle video content efficiently:

        ```ruby
        class Video < ApplicationRecord
          has_one_attached :file
          belongs_to :lesson

          after_commit :process_video, on: :create

          private

          def process_video
            VideoProcessingJob.perform_later(self)
          end
        end

        class VideoProcessingJob < ApplicationJob
          def perform(video)
            # Generate different quality versions
            # Extract thumbnail
            # Update video metadata
          end
        end
        ```

        ## Progress Tracking

        Monitor student progress effectively:

        ```ruby
        class ProgressTracker
          def initialize(student, course)
            @student = student
            @course = course
          end

          def completion_percentage
            total_lessons = @course.lessons.count
            completed_lessons = @student.lesson_completions
                                        .joins(:lesson)
                                        .where(lessons: { course: @course })
                                        .count

            return 0 if total_lessons.zero?
            (completed_lessons.to_f / total_lessons * 100).round
          end

          def estimated_completion_date
            return nil unless completion_percentage > 0

            days_elapsed = (@student.enrollments.find_by(course: @course).created_at.to_date..Date.current).count
            total_days_estimate = (days_elapsed / completion_percentage * 100).round

            @student.enrollments.find_by(course: @course).created_at.to_date + total_days_estimate.days
          end
        end
        ```

        ## Assessment System

        Create flexible assessment tools:

        ```ruby
        class Quiz < ApplicationRecord
          belongs_to :course
          has_many :questions, dependent: :destroy
          has_many :quiz_attempts

          validates :title, presence: true
          validates :time_limit, presence: true, numericality: { greater_than: 0 }
        end

        class Question < ApplicationRecord
          belongs_to :quiz
          has_many :answer_choices, dependent: :destroy

          enum question_type: { multiple_choice: 0, true_false: 1, short_answer: 2 }
        end

        class QuizAttempt < ApplicationRecord
          belongs_to :student, class_name: 'User'
          belongs_to :quiz
          has_many :student_answers

          validates :started_at, presence: true
          validate :within_time_limit, if: :submitted_at?

          private

          def within_time_limit
            return unless started_at && submitted_at

            time_taken = submitted_at - started_at
            errors.add(:submitted_at, "Quiz submitted after time limit") if time_taken > quiz.time_limit.minutes
          end
        end
        ```

        ## Communication Features

        Foster student engagement:

        ```ruby
        class Discussion < ApplicationRecord
          belongs_to :course
          belongs_to :author, class_name: 'User'
          has_many :replies, class_name: 'Discussion', foreign_key: 'parent_id'
          belongs_to :parent, class_name: 'Discussion', optional: true

          scope :top_level, -> { where(parent_id: nil) }

          validates :title, presence: true, if: :top_level?
          validates :content, presence: true
        end
        ```

        ## Analytics and Reporting

        Provide insights for educators:

        ```ruby
        class CourseAnalytics
          def initialize(course)
            @course = course
          end

          def engagement_metrics
            {
              average_completion_rate: average_completion_rate,
              most_difficult_lessons: most_difficult_lessons,
              student_participation: student_participation_rate,
              quiz_performance: average_quiz_scores
            }
          end

          private

          def average_completion_rate
            enrollments = @course.enrollments.active
            return 0 if enrollments.empty?

            total_completion = enrollments.sum do |enrollment|
              ProgressTracker.new(enrollment.student, @course).completion_percentage
            end

            (total_completion / enrollments.count).round(2)
          end

          def most_difficult_lessons
            @course.lessons
                   .joins(:lesson_completions)
                   .group('lessons.id')
                   .having('COUNT(lesson_completions.id) < ?', @course.enrollments.active.count * 0.7)
                   .order('COUNT(lesson_completions.id) ASC')
                   .limit(5)
          end
        end
        ```

        Building an effective LMS requires careful consideration of user experience, scalability, and educational pedagogy. Focus on making learning engaging and accessible while providing powerful tools for educators.
      MARKDOWN
      excerpt: "Learn how to design and build modern learning management systems with comprehensive features for online education.",
      published: false,
      published_at: nil
    }
  ]

  # Assign blog posts to users
  blog_post_assignments = [
    [ 0, 0 ], [ 0, 1 ], # John gets first 2 blog posts (Rails patterns, Hotwire)
    [ 1, 2 ], [ 1, 6 ], # Jane gets UI design and TypeScript posts
    [ 2, 3 ], [ 2, 5 ], # Alex gets API design and database optimization
    [ 3, 4 ],          # Sarah gets React Native post
    [ 4, 7 ]           # Demo user gets LMS post
  ]

  blog_post_assignments.each do |user_index, blog_post_index|
    next unless created_users[user_index] && sample_blog_posts[blog_post_index]

    user = created_users[user_index]
    blog_post_data = sample_blog_posts[blog_post_index]

    blog_post = user.blog_posts.find_or_create_by(title: blog_post_data[:title]) do |bp|
      bp.assign_attributes(blog_post_data)
    end

    if blog_post.persisted?
      puts "✅ Created blog post: #{blog_post.title} for #{user.username}"
    else
      puts "❌ Failed to create blog post #{blog_post_data[:title]}: #{blog_post.errors.full_messages.join(', ')}"
    end
  end

  # Mature product-demo user: exercises project stories, AI surfaces, GitHub evidence,
  # resume bullets, blog activity, follows, digests, and profile analytics.
  puts "\n🌿 Seeding mature proof-of-work demo user..."

  mature_user = User.find_or_initialize_by(email: "maya.demo@example.com")
  mature_user.assign_attributes(
    password: "password123",
    username: "maya_builds",
    full_name: "Maya Chen",
    job_title: "Full-stack Rails Developer",
    headline: "Full-stack developer turning product ideas into shipped Rails, Hotwire, and AI-assisted workflows.",
    bio: "I build pragmatic Rails products with thoughtful UX, reliable data models, and enough AI automation to make useful work easier to explain.",
    location: "Austin, TX",
    github_url: "https://github.com/mayabuilds",
    linkedin_url: "https://linkedin.com/in/mayachen-dev",
    website_url: "https://maya-builds.dev",
    twitter_url: "https://x.com/maya_builds",
    contact_email: "maya.demo@example.com",
    resume_url: "https://maya-builds.dev/resume",
    account_status: "active",
    allow_career_architect: true,
    open_for_work: true,
    featured: true,
    featured_at: 2.months.ago,
    last_login_at: 3.hours.ago,
    skills: [
      "Ruby on Rails",
      "Hotwire",
      "PostgreSQL",
      "Tailwind CSS",
      "AI product workflows",
      "GitHub API",
      "Background jobs",
      "Product design"
    ],
    work_preferences: {
      "remote_preference" => "hybrid",
      "availability" => "immediate",
      "work_types" => [ "full_time", "contract" ],
      "preferred_roles" => [ "Full-stack Developer", "Product Engineer", "Rails Developer" ],
      "message" => "Open to strong product teams building developer tools, civic products, or AI-assisted workflows."
    }
  )
  mature_user.save!
  mature_user.active!
  mature_user.update_columns(created_at: 8.months.ago, updated_at: 1.hour.ago)
  created_users << mature_user unless created_users.include?(mature_user)

  mature_projects = [
    {
      title: "AnchorCRM Field Notes",
      description: "A Rails and Hotwire CRM workspace for independent consultants to capture client context, follow-ups, and project signals without maintaining a heavyweight sales pipeline.",
      technologies_used: [ "Ruby on Rails", "Hotwire", "PostgreSQL", "Tailwind CSS", "Solid Queue", "Pundit" ],
      source_code_url: "https://github.com/mayabuilds/anchorcrm-field-notes",
      live_url: "https://anchorcrm-demo.example.com",
      status: "published",
      featured: true,
      display_order: 1,
      project_insight_enabled: true,
      github_insights_enabled: true,
      github_insights_sync_status: "ready",
      github_insights_last_synced_at: 1.day.ago,
      github_insights_summary: {
        "project_overview" => "Rails CRM workspace focused on lightweight client follow-up and proof-of-work context.",
        "tech_stack" => [ "Ruby on Rails", "Hotwire", "PostgreSQL", "Tailwind CSS", "Solid Queue" ],
        "highlights" => [
          "Uses Hotwire for low-JavaScript interaction patterns",
          "Separates tenant-scoped records with explicit authorization checks",
          "Includes background digest preparation for follow-up reminders"
        ],
        "caveats" => [ "Demo data uses seeded client records rather than production traffic" ]
      },
      project_insight_analysis: {
        "repository" => { "name" => "anchorcrm-field-notes", "default_branch" => "main" },
        "languages" => { "Ruby" => 71, "HTML" => 16, "JavaScript" => 8, "CSS" => 5 },
        "manifests" => [ "Gemfile", "package.json" ],
        "readme_excerpt" => "AnchorCRM Field Notes helps consultants keep client context, tasks, and relationship signals close to the work.",
        "recent_commits" => [
          "Add proof-of-work summary panel",
          "Introduce scoped project notes policy",
          "Refine Hotwire follow-up composer"
        ],
        "structure" => [ "app/controllers", "app/models", "app/views", "app/services", "test" ]
      },
      project_story: {
        "version" => 1,
        "overview" => "AnchorCRM Field Notes is a focused CRM workspace for independent consultants who need just enough structure to remember client context and act on follow-ups.",
        "problem" => "Most CRM tools felt too sales-heavy for small consulting relationships. The project explores a lighter way to connect people, projects, notes, and next actions.",
        "intended_users" => "Independent consultants, freelance developers, and small service teams managing a handful of high-context relationships.",
        "why_built" => "I wanted a product-shaped Rails project that forced me to think through authorization, product hierarchy, and daily-use ergonomics instead of only CRUD screens.",
        "role" => "I designed the data model, built the Rails/Hotwire workflows, added Pundit authorization, and shaped the UI around repeated daily use.",
        "technical_decisions" => "I kept controllers thin, pushed relationship logic into models/services, used Turbo Frames for contextual updates, and made tenant ownership explicit at query boundaries.",
        "hardest_challenge" => "The hardest part was keeping the product useful without letting it become a full enterprise CRM. I had to keep trimming features back to the core follow-up loop.",
        "lessons_learned" => "I learned how much product clarity affects architecture. A small, repeated workflow benefits more from precise boundaries than from broad feature coverage.",
        "demonstrates" => "This project demonstrates Rails product engineering, authorization discipline, Hotwire interaction design, and comfort turning a fuzzy workflow into a usable product surface.",
        "promotion_notes" => "Good for resume bullets about product thinking, Rails architecture, tenant scoping, and Hotwire UX."
      }
    },
    {
      title: "DevProof Story Builder",
      description: "An AI-assisted proof-of-work tool that helps developers turn project notes, GitHub signals, and technical decisions into structured portfolio stories.",
      technologies_used: [ "Ruby on Rails", "OpenAI API", "Hotwire", "PostgreSQL", "Tailwind CSS", "JSONB" ],
      source_code_url: "https://github.com/mayabuilds/devproof-story-builder",
      live_url: "https://devproof-demo.example.com",
      status: "published",
      featured: true,
      display_order: 2,
      project_insight_enabled: true,
      github_insights_enabled: true,
      github_insights_sync_status: "ready",
      github_insights_last_synced_at: 2.days.ago,
      github_insights_summary: {
        "project_overview" => "AI-assisted project story workflow that turns structured inputs into reviewable proof-of-work content.",
        "tech_stack" => [ "Rails", "OpenAI API", "Hotwire", "PostgreSQL JSONB" ],
        "highlights" => [
          "Uses strict JSON parsing for AI suggestions",
          "Keeps generated content reviewable before applying it",
          "Separates public story content from owner-only asset generation"
        ],
        "caveats" => [ "AI output is intentionally conservative and owner-reviewed" ]
      },
      project_insight_analysis: {
        "repository" => { "name" => "devproof-story-builder", "default_branch" => "main" },
        "languages" => { "Ruby" => 68, "HTML" => 18, "JavaScript" => 9, "CSS" => 5 },
        "manifests" => [ "Gemfile", "package.json" ],
        "readme_excerpt" => "DevProof Story Builder helps developers explain what they built, why it matters, and what it demonstrates.",
        "recent_commits" => [
          "Add review-before-apply story suggestions",
          "Normalize AI response contract",
          "Add copy-only resume bullet generator"
        ],
        "structure" => [ "app/services/project_story_builder", "app/services/project_resume_bullets", "app/views/projects" ]
      },
      project_story: {
        "version" => 1,
        "overview" => "DevProof Story Builder is an AI-assisted workflow for turning rough project context into structured proof-of-work stories.",
        "problem" => "Developers often build meaningful projects but struggle to explain the problem, their role, the hard parts, and the evidence behind the work.",
        "intended_users" => "Early-career developers, career changers, independent builders, and engineers preparing for interviews or portfolio reviews.",
        "why_built" => "I built it to explore how AI could support storytelling without taking away user control or inventing unsupported accomplishments.",
        "role" => "I designed the story schema, built the project-scoped AI services, implemented strict response parsing, and created the review/apply UI.",
        "technical_decisions" => "The project uses versioned JSONB story fields, single-turn AI services, defensive parsers, session-backed transient suggestions, and explicit source-field protection.",
        "hardest_challenge" => "The hardest challenge was making AI useful without making it too magical. The system needed to help with phrasing while preserving user review and factual boundaries.",
        "lessons_learned" => "I learned to treat AI output as suggestions that need product constraints, parsing contracts, and conservative defaults.",
        "demonstrates" => "This project demonstrates AI product design, Rails service architecture, JSONB modeling, prompt-contract thinking, and user-centered review flows.",
        "promotion_notes" => "Good for bullets about AI workflows, strict JSON parsing, review-before-apply UX, and grounded content generation."
      }
    },
    {
      title: "Neighborhood Pantry Map",
      description: "A community resource map that lets volunteers publish pantry hours, donation needs, accessibility notes, and neighborhood-level updates.",
      technologies_used: [ "Ruby on Rails", "PostgreSQL", "Mapbox", "Stimulus", "Tailwind CSS" ],
      source_code_url: "https://github.com/mayabuilds/neighborhood-pantry-map",
      live_url: "https://pantry-map-demo.example.com",
      status: "published",
      featured: false,
      display_order: 3,
      project_insight_enabled: true,
      github_insights_enabled: true,
      github_insights_sync_status: "ready",
      github_insights_last_synced_at: 4.days.ago,
      github_insights_summary: {
        "project_overview" => "Volunteer-maintained map for local pantry availability and donation needs.",
        "tech_stack" => [ "Rails", "PostgreSQL", "Mapbox", "Stimulus" ],
        "highlights" => [
          "Models recurring schedules and temporary closure notices",
          "Includes moderation states for community-submitted updates",
          "Uses simple map filters for accessibility and hours"
        ],
        "caveats" => [ "Location data in demo is fictional" ]
      },
      project_insight_analysis: {
        "repository" => { "name" => "neighborhood-pantry-map", "default_branch" => "main" },
        "languages" => { "Ruby" => 62, "HTML" => 20, "JavaScript" => 13, "CSS" => 5 },
        "manifests" => [ "Gemfile", "package.json" ],
        "readme_excerpt" => "A volunteer-friendly way to keep local food pantry information accurate and easy to browse.",
        "recent_commits" => [
          "Add moderation queue for pantry updates",
          "Improve schedule rendering for closures",
          "Add accessible map filter labels"
        ],
        "structure" => [ "app/models/pantry", "app/models/update_submission", "app/javascript/controllers" ]
      },
      project_story: {
        "version" => 1,
        "overview" => "Neighborhood Pantry Map is a volunteer-friendly resource map for keeping pantry availability and donation needs current.",
        "problem" => "Community resource information often becomes stale, especially when hours or needs change quickly.",
        "intended_users" => "Local volunteers, pantry coordinators, and residents looking for accurate nearby resources.",
        "why_built" => "I wanted to practice building a civic-tech workflow where trust, moderation, and clarity mattered as much as the map itself.",
        "role" => "I built the Rails data model, schedule logic, moderation states, and Stimulus map interactions.",
        "technical_decisions" => "I separated pantry records from update submissions so volunteers could suggest changes without immediately changing public information.",
        "hardest_challenge" => "The hardest part was modeling recurring hours, one-off closures, and donation needs without making the editing flow confusing.",
        "lessons_learned" => "I learned to model uncertainty directly: community updates need review states, timestamps, and clear public context.",
        "demonstrates" => "This project demonstrates product-minded data modeling, civic-tech UX, moderation workflows, and accessible map interactions.",
        "promotion_notes" => "Good for bullets about data modeling, moderation, accessibility, and civic product thinking."
      }
    },
    {
      title: "Interview Prep Companion",
      description: "A draft AI practice tool for turning project stories into interview talking points, follow-up questions, and reflection prompts.",
      technologies_used: [ "Ruby on Rails", "OpenAI API", "PostgreSQL", "Hotwire" ],
      source_code_url: "https://github.com/mayabuilds/interview-prep-companion",
      status: "draft",
      featured: false,
      display_order: 4,
      project_insight_enabled: false,
      github_insights_enabled: false,
      github_insights_sync_status: "never",
      project_story: {
        "version" => 1,
        "overview" => "Interview Prep Companion is an early draft tool for helping developers practice explaining their projects in interviews.",
        "problem" => "Developers often have project details available but need help turning them into confident spoken explanations.",
        "role" => "I am prototyping the project-scoped prompt flow and deciding which outputs should come after resume bullets.",
        "hardest_challenge" => "The biggest challenge is keeping the tool focused on practice instead of becoming a generic chat assistant.",
        "lessons_learned" => "",
        "demonstrates" => "",
        "promotion_notes" => "Draft project that should show partial story guidance and unpublished owner-only behavior."
      }
    }
  ]

  mature_projects.each do |project_attrs|
    story = project_attrs.delete(:project_story)
    project = mature_user.projects.find_or_initialize_by(title: project_attrs[:title])
    project.assign_attributes(project_attrs.merge(project_story: story))
    project.save!
    project.update_columns(created_at: rand(2..7).months.ago, updated_at: rand(1..18).days.ago)

    if project.github_insights_ready?
      project.project_github_insight_snapshots.destroy_all
      project.project_github_insight_snapshots.create!(
        sync_type: "deep",
        source: "manual",
        captured_at: project.github_insights_last_synced_at || 1.day.ago,
        duration_ms: rand(1_200..3_800),
        repo_payload: {
          "url" => project.project_github_repo_url,
          "default_branch" => "main",
          "visibility" => "public"
        },
        metrics_payload: {
          "commits_analyzed" => rand(32..96),
          "files_seen" => rand(45..140),
          "languages" => project.project_insight_analysis["languages"] || {}
        },
        highlights_payload: {
          "highlights" => project.github_insights_summary["highlights"] || [],
          "tech_stack" => project.github_insights_summary["tech_stack"] || []
        },
        errors_payload: {}
      )
    end

    puts "✅ Seeded mature project: #{project.title}"
  end

  mature_blog_posts = [
    {
      title: "What AI Should and Should Not Do in a Developer Portfolio",
      content: <<~MARKDOWN,
        # What AI Should and Should Not Do in a Developer Portfolio

        AI is useful when it helps developers explain real work more clearly. It becomes risky when it invents impact, smooths over uncertainty, or turns every project into the same polished story.

        In my own proof-of-work experiments, the best pattern has been review-before-apply. The model can suggest structure, summarize evidence, and make rough notes easier to read. The developer still owns the claims.

        ## Useful constraints

        - Ground suggestions in real project fields.
        - Keep generated copy editable.
        - Separate GitHub-derived observations from personal claims.
        - Prefer conservative phrasing when context is thin.

        That combination makes AI feel like a writing partner instead of a brag generator.
      MARKDOWN
      excerpt: "A practical note on using AI to clarify real developer work without inventing accomplishments.",
      published: true,
      published_at: 6.weeks.ago,
      featured: true,
      views_count: 248
    },
    {
      title: "Designing Rails Features Around the Smallest Useful Loop",
      content: <<~MARKDOWN,
        # Designing Rails Features Around the Smallest Useful Loop

        The fastest way for me to lose product clarity is to build every adjacent feature at once. The better pattern is to find the smallest useful loop and make that path obvious.

        For a proof-of-work app, that loop is simple:

        1. Pick a real project.
        2. Explain what it is and why it matters.
        3. Publish the story.
        4. Reuse the story somewhere practical.

        Rails works well for this style of product development because the domain model can stay close to the UI. A small model helper, a presenter, and a focused service can often do more than a large abstraction.
      MARKDOWN
      excerpt: "Notes on keeping Rails product work centered on one useful loop at a time.",
      published: true,
      published_at: 3.weeks.ago,
      featured: false,
      views_count: 176
    },
    {
      title: "Sketches for Interview Practice from Project Stories",
      content: <<~MARKDOWN,
        # Sketches for Interview Practice from Project Stories

        This is a draft note about using project stories as interview preparation material.

        The idea is not to memorize perfect answers. The better goal is to understand the real decisions behind a project well enough to explain tradeoffs naturally.
      MARKDOWN
      excerpt: "Draft thoughts on turning project stories into interview preparation.",
      published: false,
      published_at: nil,
      featured: false,
      views_count: 0
    }
  ]

  mature_blog_posts.each do |attrs|
    post = mature_user.blog_posts.find_or_initialize_by(title: attrs[:title])
    post.assign_attributes(attrs)
    post.save!
    post.update_columns(created_at: (attrs[:published_at] || 5.days.ago) - 2.days, updated_at: rand(1..10).days.ago)
    puts "✅ Seeded mature blog post: #{post.title}"
  end

  mature_user.create_digest_preference! unless mature_user.digest_preference
  mature_user.digest_preference.update!(
    enabled: true,
    frequency: "weekly",
    include_projects: true,
    include_blog_posts: true,
    include_profile_updates: true,
    timezone: "America/Chicago",
    digest_time: "08:30",
    last_sent_at: 1.week.ago
  )

  GitHubProfileSnapshot.find_or_initialize_by(user: mature_user).tap do |snapshot|
    snapshot.assign_attributes(
      username: "mayabuilds",
      fetched_at: 2.days.ago,
      payload: {
        "login" => "mayabuilds",
        "name" => "Maya Chen",
        "public_repos" => 34,
        "followers" => 214,
        "following" => 89,
        "top_languages" => [ "Ruby", "JavaScript", "HTML", "CSS" ],
        "recent_repositories" => [ "devproof-story-builder", "anchorcrm-field-notes", "neighborhood-pantry-map" ]
      }
    )
    snapshot.save!
  end

  architect_session = mature_user.architect_sessions.find_or_initialize_by(mode: "profile_builder", goal: "both")
  architect_session.assign_attributes(
    status: "completed",
    question_count: 3,
    context_version: 1,
    target_type: nil,
    target_data: {},
    context_snapshot: {
      "profile" => {
        "headline" => mature_user.headline,
        "skills" => mature_user.skills,
        "projects" => mature_user.projects.published.pluck(:title)
      },
      "source" => "seeded mature demo"
    },
    generated_headline: "Rails product engineer building proof-of-work tools with Hotwire, PostgreSQL, and grounded AI workflows.",
    generated_bio: "Maya is a full-stack Rails developer focused on product workflows that make complex work easier to understand. Her recent projects combine Hotwire, PostgreSQL, GitHub-derived evidence, and AI-assisted writing flows with careful review and authorization boundaries.",
    result_data: {
      "summary" => "Completed profile builder session",
      "suggested_skills" => [ "Rails", "Hotwire", "AI-assisted UX", "PostgreSQL", "Product engineering" ]
    }
  )
  architect_session.save!
  architect_session.architect_messages.destroy_all
  [
    [ "assistant", "What kind of developer story do you want your profile to tell?", "profile_direction" ],
    [ "user", "I want it to show that I can turn ambiguous product ideas into focused Rails workflows.", "profile_direction" ],
    [ "assistant", "Which projects best prove that?", "proof_points" ],
    [ "user", "AnchorCRM, DevProof Story Builder, and the pantry map all show different parts of that.", "proof_points" ],
    [ "assistant", "Generated a concise profile direction centered on Rails product engineering and grounded AI workflows.", "final_summary" ]
  ].each_with_index do |(role, content, topic), index|
    architect_session.architect_messages.create!(
      role: role,
      content: content,
      topic: topic,
      insight_type: index == 4 ? "summary" : nil,
      metadata: { "seeded" => true },
      sequence: index
    )
  end

  # Social graph and analytics for a user who has been active for a while.
  (created_users - [ mature_user ]).first(4).each do |other_user|
    mature_user.follow!(other_user)
    other_user.follow!(mature_user)
  end

  mature_user.profile_views.delete_all
  36.times do |index|
    mature_user.profile_views.create!(
      visitor_ip: "198.51.100.#{index + 10}",
      user_agent: index.even? ? "Mozilla/5.0 Chrome Demo" : "Mozilla/5.0 Safari Demo",
      referrer: [ "https://github.com", "https://linkedin.com", "https://google.com", "https://dev.to" ].sample,
      visited_at: rand(1..60).days.ago
    )
  end

  puts "✅ Mature demo user ready: maya.demo@example.com / password123"

  puts "\n🎉 Seeding completed!"
  puts "\nSample users created:"
  puts "Email: john@example.com | Username: johndoe | Password: password123"
  puts "Email: jane@example.com | Username: janesmith | Password: password123"
  puts "Email: alex@example.com | Username: alexdev | Password: password123"
  puts "Email: sarah@example.com | Username: sarahcode | Password: password123"
  puts "Email: demo@example.com | Username: demouser | Password: password123"
  puts "Email: maya.demo@example.com | Username: maya_builds | Password: password123"
  puts "\nYou can sign in with any of these accounts to explore the application!"

  # Load visitor data
  load Rails.root.join('db', 'seeds', 'visitor_data.rb')
else
  puts "Skipping seeds - not in development environment"
end
