# DevvMe - Developer Portfolio Platform

[![Ruby on Rails](https://img.shields.io/badge/Ruby%20on%20Rails-8.0.2-red.svg)](https://rubyonrails.org/)
[![Ruby](https://img.shields.io/badge/Ruby-3.4.1-red.svg)](https://www.ruby-lang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue.svg)](https://www.postgresql.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind%20CSS-Styling-38B2AC.svg)](https://tailwindcss.com/)
[![Hotwire](https://img.shields.io/badge/Hotwire-SPA--like-orange.svg)](https://hotwired.dev/)

DevvMe is a modern, feature-rich platform that empowers developers to create stunning professional portfolios. Built with Rails 8 and the latest web technologies, it provides an intuitive interface for showcasing projects, skills, and professional experience.

## 🚀 Features

### Portfolio Management
- **Project Showcase**: Create detailed project entries with descriptions, technologies, images, and live demos
- **Drag & Drop Reordering**: Easily reorder projects with intuitive drag-and-drop functionality
- **Status Management**: Organize projects as draft, published, or archived
- **Image Uploads**: Upload project images and thumbnails with Active Storage
- **URL Validation**: Automatic URL normalization and validation for project links

### User Experience
- **Professional Profiles**: Comprehensive user profiles with avatars, bio, and social links
- **Dashboard Analytics**: Track portfolio performance with detailed statistics
- **Progress Tracking**: Profile completion percentage to encourage full setup
- **Responsive Design**: Mobile-first design that looks great on all devices
- **Dark Mode Support**: Built-in dark/light theme switching

### Technical Excellence
- **Modern Rails 8**: Latest Rails features with Solid Queue for background jobs
- **Hotwire Integration**: SPA-like experience with Turbo and Stimulus
- **Performance Optimized**: Database indexing, eager loading, and caching strategies
- **Security First**: Comprehensive authentication with Devise and security validations
- **SEO Friendly**: Friendly URLs with FriendlyId gem

## 🛠 Technology Stack

### Backend
- **Ruby 3.4.1** - Latest Ruby features and performance improvements
- **Rails 8.0.2** - Modern Rails with enhanced performance
- **PostgreSQL** - Robust, scalable database solution
- **Devise** - Flexible authentication system
- **Active Storage** - File upload and image processing
- **Solid Queue** - Database-backed job processing (Rails default)
- **FriendlyId** - SEO-friendly URLs

### Frontend
- **Hotwire (Turbo + Stimulus)** - Modern, reactive user interface
- **Tailwind CSS** - Utility-first CSS framework
- **Flowbite Components** - Professional UI component library
- **SortableJS** - Drag-and-drop functionality
- **Responsive Design** - Mobile-first approach

### DevOps & Deployment
- **Docker & Kamal** - Containerized deployment
- **Thruster** - HTTP asset caching and compression
- **Solid Cache** - Database-backed caching
- **Image Processing** - Automated image optimization

## 📋 Prerequisites

- Ruby 3.4.1+
- Node.js 18+
- PostgreSQL 14+
- Redis (optional, for advanced caching)

## 🚀 Quick Start

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/devvme_app.git
   cd devvme_app
   ```

2. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

3. **Setup database**
   ```bash
   bin/rails db:setup
   bin/rails db:migrate
   bin/rails db:seed
   ```

4. **Start the development server**
   ```bash
   bin/dev
   ```

5. **Visit the application**
   Open [http://localhost:3000](http://localhost:3000) in your browser

### Docker Development

```bash
docker-compose up --build
```

## 🏗 Project Structure

```
devvme_app/
├── app/
│   ├── controllers/         # Application controllers
│   ├── models/             # ActiveRecord models
│   ├── views/              # ERB templates
│   ├── javascript/         # Stimulus controllers
│   └── assets/             # CSS and images
├── config/
│   ├── environments/       # Environment-specific configs
│   ├── initializers/       # App initialization
│   └── deploy.yml          # Kamal deployment config
├── db/
│   ├── migrate/           # Database migrations
│   └── seeds.rb           # Sample data
└── test/                  # Comprehensive test suite
```

## 🎯 Key Models

### User Model
- Authentication with Devise
- Profile information and social links
- Avatar uploads with Active Storage
- Profile completion tracking
- SEO-friendly URLs with FriendlyId

### Project Model
- Comprehensive project information
- Technology stack tracking (up to 10 technologies)
- Status management (draft/published/archived)
- Image attachments with thumbnails
- Drag-and-drop reordering
- URL validation and normalization

## 🎨 UI Components

### Dashboard Features
- **Statistics Cards**: Project counts, status distribution
- **Recent Activity**: Latest project updates
- **Profile Completion**: Progress tracking
- **Quick Actions**: Fast access to common tasks

### Project Management
- **Interactive Forms**: Dynamic technology tagging
- **Image Previews**: Real-time image upload previews
- **Sortable Lists**: Drag-and-drop project reordering
- **Status Indicators**: Visual project status management

## 🔒 Security Features

- **Authentication**: Secure user authentication with Devise
- **Authorization**: User-scoped data access
- **Input Validation**: Comprehensive model validations
- **File Upload Security**: Image type and size validation
- **URL Sanitization**: Automatic URL normalization
- **CSRF Protection**: Built-in Rails CSRF protection

## 📊 Testing

The application includes comprehensive tests:

```bash
# Run all tests
bin/rails test

# Run specific test suites
bin/rails test:models
bin/rails test:controllers
bin/rails test:integration
bin/rails test:system

# Run with coverage
bin/rails test:coverage
```

### Test Coverage
- **Unit Tests**: Model validations and business logic
- **Integration Tests**: User workflows and API endpoints
- **System Tests**: End-to-end user interactions
- **Security Tests**: Authentication and authorization

## 🚀 Deployment

### Production Deployment with Kamal

1. **Configure deployment**
   ```bash
   # Edit config/deploy.yml with your server details
   vim config/deploy.yml
   ```

2. **Setup secrets**
   ```bash
   bin/kamal env push
   ```

3. **Deploy**
   ```bash
   bin/kamal deploy
   ```

### Environment Variables

```bash
# Required for production
RAILS_MASTER_KEY=your_master_key
DATABASE_URL=postgresql://username:password@host:port/database

# Optional
SOLID_QUEUE_IN_PUMA=true
WEB_CONCURRENCY=2
JOB_CONCURRENCY=3
```

## 🔧 Configuration

### Database Configuration
```yaml
# config/database.yml
production:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

### Background Jobs
The application uses Solid Queue (Rails 8 default) for background job processing:

```ruby
# config/queue.yml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: 2
```

## 📈 Performance Optimizations

- **Database Indexing**: Optimized queries with proper indexes
- **Eager Loading**: Prevents N+1 queries
- **Image Optimization**: Automatic image resizing and compression
- **Caching**: Fragment and Russian Doll caching strategies
- **Asset Pipeline**: Optimized CSS and JavaScript delivery

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the [Ruby Style Guide](https://rubystyle.guide/)
- Write comprehensive tests for new features
- Use conventional commit messages
- Update documentation for significant changes

## 📝 API Documentation

### Project Reordering API
```javascript
// POST /projects/reorder
{
  "project_ids": [3, 1, 2]
}

// Response
{
  "status": "success",
  "message": "Projects reordered successfully"
}
```

## 🐛 Troubleshooting

### Common Issues

**Image uploads not working**
- Check Active Storage configuration
- Verify image processing dependencies
- Ensure proper file permissions

**Background jobs not processing**
- Verify Solid Queue configuration
- Check database connectivity
- Monitor job queue status

**Styling issues**
- Rebuild Tailwind CSS: `bin/rails assets:precompile`
- Check for conflicting CSS rules
- Verify Flowbite component imports

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ruby on Rails](https://rubyonrails.org/) - The web framework
- [Tailwind CSS](https://tailwindcss.com/) - Utility-first CSS framework
- [Hotwire](https://hotwired.dev/) - Modern web application framework
- [Flowbite](https://flowbite.com/) - Component library
- [Devise](https://github.com/heartcombo/devise) - Authentication solution

## 📞 Support

- **Documentation**: [Wiki](https://github.com/yourusername/devvme_app/wiki)
- **Issues**: [GitHub Issues](https://github.com/yourusername/devvme_app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/devvme_app/discussions)

---

**Built with ❤️ for the developer community**

---

*DevvMe - Empowering developers to showcase their best work with professional, modern portfolios.*