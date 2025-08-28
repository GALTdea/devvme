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
