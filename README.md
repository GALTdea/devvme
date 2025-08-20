# DevVme - Developer Portfolio Platform

A modern developer portfolio platform built with Ruby on Rails 8, featuring user authentication, project management, and responsive design.

## Features

- **User Authentication**: Secure sign up/sign in with Devise
- **Profile Management**: Complete user profiles with avatars, bio, and social links
- **Project Showcase**: Create and manage portfolio projects with images
- **Responsive Design**: Works perfectly on desktop, tablet, and mobile devices
- **Modern UI**: Built with Tailwind CSS and Flowbite components
- **SEO-Friendly URLs**: Using FriendlyId for clean URLs
- **Image Processing**: Active Storage with image variants for different sizes
- **Real-time Updates**: Hotwire/Turbo for fast, modern web experience

## Technology Stack

### Backend
- **Ruby 3.4.1** - Latest Ruby version
- **Rails 8.0.2** - Latest Rails framework
- **PostgreSQL** - Primary database
- **Devise** - Authentication
- **FriendlyId** - SEO-friendly URLs
- **Active Storage** - File uploads and image processing
- **Solid Queue** - Background job processing [[memory:3928236]]

### Frontend
- **Hotwire (Turbo + Stimulus)** - Modern JavaScript framework
- **Tailwind CSS 4.1** - Utility-first CSS framework
- **Flowbite Components v3.1.2** - Pre-built UI components
- **Responsive Design** - Mobile-first approach

### Development Tools
- **RuboCop** - Code linting and formatting
- **Minitest** - Testing framework
- **Brakeman** - Security scanner

## Installation & Setup

### Prerequisites

- Ruby 3.4.1
- Rails 8.0.2
- PostgreSQL
- Node.js (for JavaScript dependencies)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd devvme_app
   ```

2. **Install dependencies**
   ```bash
   # Install Ruby gems
   bundle install
   
   # Install JavaScript packages
   npm install
   ```

3. **Database setup**
   ```bash
   # Create and setup the database
   bin/rails db:create
   bin/rails db:migrate
   
   # Load sample data (development only)
   bin/rails db:seed
   ```

4. **Start the development server**
   ```bash
   # Option 1: Using the dev script (recommended)
   bin/dev
   
   # Option 2: Manual start
   bin/rails server
   ```

5. **Access the application**
   - Open your browser to `http://localhost:3000`
   - Sign up for a new account or use sample accounts from seeds

### Sample Accounts (Development)

After running `bin/rails db:seed`, you can use these test accounts:

- **Email**: john@example.com | **Password**: password123
- **Email**: jane@example.com | **Password**: password123  
- **Email**: alex@example.com | **Password**: password123
- **Email**: sarah@example.com | **Password**: password123
- **Email**: demo@example.com | **Password**: password123

## Testing

### Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test files
bin/rails test test/models/user_test.rb
bin/rails test test/controllers/dashboard_controller_test.rb

# Run tests with coverage
COVERAGE=true bin/rails test
```

### Test Structure

- **Model Tests**: Comprehensive validation and business logic tests
- **Controller Tests**: Authentication and authorization tests
- **Integration Tests**: End-to-end user flow tests
- **System Tests**: Browser-based feature tests

## Code Quality

### Linting and Formatting

```bash
# Check code style
bin/rubocop

# Auto-fix style issues
bin/rubocop -A

# Security scan
bin/brakeman
```

### Code Coverage

Test coverage is tracked using SimpleCov. Run tests with `COVERAGE=true` to generate coverage reports.

## Deployment

### Production Checklist

1. **Environment Variables**
   ```bash
   # Required environment variables
   SECRET_KEY_BASE=<your-secret-key>
   DATABASE_URL=<your-database-url>
   RAILS_ENV=production
   ```

2. **Database Migration**
   ```bash
   bin/rails db:migrate RAILS_ENV=production
   ```

3. **Asset Compilation**
   ```bash
   bin/rails assets:precompile RAILS_ENV=production
   ```

### Deployment Options

- **Heroku**: Ready for Heroku deployment with Procfile
- **Docker**: Dockerfile included for containerized deployments
- **Traditional VPS**: Compatible with Capistrano or manual deployment

## Application Structure

### Models

- **User**: Handles authentication, profiles, and user data
- **Project**: Manages portfolio projects and their metadata

### Controllers

- **HomeController**: Landing page and public content
- **DashboardController**: User dashboard with statistics
- **ProfilesController**: Profile management and editing
- **Devise Controllers**: Authentication flows

### Key Features Implementation

#### User Authentication
- Devise configuration with custom views
- Username-based authentication alongside email
- Profile completion tracking
- Social media link validation and normalization

#### Project Management
- File upload with Active Storage
- Image variants for different display sizes
- Project status management (draft, published, archived)
- URL validation and normalization

#### SEO & Performance
- FriendlyId for SEO-friendly URLs
- Image optimization with variants
- Responsive images with appropriate sizing
- Meta tags and structured data ready

## Development Workflow

### Adding New Features

1. **Create a new branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Write tests first** (TDD approach)
   ```bash
   # Create test file
   touch test/models/your_model_test.rb
   ```

3. **Implement the feature**
   - Add model validations and business logic
   - Create controller actions
   - Build views with Tailwind CSS
   - Add Stimulus controllers for interactivity

4. **Test thoroughly**
   ```bash
   bin/rails test
   bin/rubocop
   ```

5. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   git push origin feature/your-feature-name
   ```

### Database Changes

```bash
# Generate migration
bin/rails generate migration DescriptiveName

# Run migration
bin/rails db:migrate

# Rollback if needed
bin/rails db:rollback
```

### Adding UI Components

1. **Use Tailwind CSS** for styling
2. **Leverage Flowbite components** for complex UI elements
3. **Add Stimulus controllers** for JavaScript behavior
4. **Ensure responsive design** on all screen sizes

## Troubleshooting

### Common Issues

1. **Database connection errors**
   - Check PostgreSQL is running
   - Verify database.yml configuration
   - Ensure database exists

2. **Asset compilation issues**
   - Clear tmp files: `bin/rails tmp:clear`
   - Restart server: `bin/dev`
   - Check for JavaScript errors in browser console

3. **Test failures**
   - Ensure test database is properly migrated
   - Check for fixture conflicts
   - Verify factory data is valid

### Getting Help

1. Check the Rails logs: `tail -f log/development.log`
2. Use Rails console for debugging: `bin/rails console`
3. Run tests in verbose mode: `bin/rails test -v`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Ensure all tests pass and code style is correct
5. Submit a pull request

## License

This project is available as open source under the terms of the [MIT License](LICENSE).