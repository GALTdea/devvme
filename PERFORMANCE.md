# Performance Optimization Guide

This document outlines the performance optimizations implemented for public profiles and provides instructions for testing and monitoring performance.

## Implemented Optimizations

### 1. Fragment Caching
- **Profile Header**: Cached for 1 hour
- **Profile Stats**: Cached for 30 minutes  
- **Projects Section**: Cached for 1 hour
- **Blog Posts Section**: Cached for 1 hour

Cache keys are automatically invalidated when user data or associated content changes.

### 2. Database Optimization
- **Eager Loading**: Implemented `includes` for user avatars, project thumbnails, and blog posts
- **Optimized Queries**: Reduced N+1 queries throughout the application
- **Selective Loading**: Only load published content for public profiles

### 3. Image Optimization
- **Lazy Loading**: All images load only when visible
- **Responsive Images**: Automatic srcset generation for different screen sizes
- **Image Variants**: Optimized sizes for avatars (thumbnail, medium, large)
- **WebP Support**: Modern image formats when supported

### 4. Caching Strategy
- **HTTP Caching**: Public profiles cached for 15 minutes with ETag support
- **Fragment Caching**: Individual sections cached independently
- **Asset Caching**: Static assets cached with fingerprinting

### 5. SEO & Social Optimization
- **XML Sitemap**: Automatically generated and cached
- **Meta Tags**: Comprehensive Open Graph and Twitter Card support
- **Structured Data**: JSON-LD schema markup for better search results
- **Canonical URLs**: Proper canonical URL handling

## Testing Performance

### PageSpeed Insights Testing

1. **Open PageSpeed Insights**: https://pagespeed.web.dev/
2. **Test URLs**:
   - Homepage: `https://yourdomain.com`
   - Profile Page: `https://yourdomain.com/username`
   - Blog: `https://yourdomain.com/blog`

### Expected Performance Scores

**Target Metrics:**
- **Performance**: 90+ (mobile), 95+ (desktop)
- **Accessibility**: 95+
- **Best Practices**: 90+
- **SEO**: 95+

**Core Web Vitals:**
- **LCP (Largest Contentful Paint)**: < 2.5s
- **FID (First Input Delay)**: < 100ms
- **CLS (Cumulative Layout Shift)**: < 0.1

### Testing Tools

1. **Google PageSpeed Insights**: Overall performance and Core Web Vitals
2. **GTmetrix**: Detailed performance analysis
3. **WebPageTest**: Advanced performance testing
4. **Chrome DevTools**: Local performance profiling

### Performance Monitoring

The application includes built-in performance monitoring:

- **Core Web Vitals**: Automatic tracking via Google Analytics
- **Long Tasks**: Detection of JavaScript tasks > 50ms
- **Navigation Timing**: Page load performance metrics
- **Resource Loading**: Monitoring of critical resource timing

## Optimization Checklist

### Before Deployment
- [ ] Enable production caching (`config.cache_classes = true`)
- [ ] Configure CDN for static assets
- [ ] Set up Google Analytics ID for monitoring
- [ ] Configure proper cache headers
- [ ] Optimize images and enable compression

### After Deployment
- [ ] Test with PageSpeed Insights
- [ ] Verify Core Web Vitals
- [ ] Check mobile performance
- [ ] Test social sharing previews
- [ ] Validate structured data

## Performance Configuration

### Environment Variables
```bash
# Google Analytics
GOOGLE_ANALYTICS_ID=GA_MEASUREMENT_ID

# Redis (for caching)
REDIS_URL=redis://localhost:6379/0

# CDN Configuration
CDN_HOST=https://cdn.yourdomain.com
```

### Production Settings
```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
config.action_controller.perform_caching = true
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000'
}
```

## Monitoring & Alerts

### Key Metrics to Monitor
1. **Page Load Time**: < 3 seconds
2. **Time to First Byte**: < 500ms
3. **Cache Hit Rate**: > 80%
4. **Error Rate**: < 1%

### Google Analytics Events
The application automatically tracks:
- Profile views and engagement
- Social sharing activity
- Performance metrics
- Core Web Vitals

### Setting Up Alerts
1. **Google Analytics**: Set up custom alerts for performance degradation
2. **New Relic/DataDog**: Application performance monitoring
3. **Uptime Monitoring**: Services like Pingdom or UptimeRobot

## Common Performance Issues

### Slow Profile Loading
- Check cache hit rates
- Verify database query performance
- Monitor image loading times

### Poor Mobile Performance
- Test on actual mobile devices
- Check image optimization
- Verify touch targets and layout shifts

### Social Sharing Problems
- Validate Open Graph tags
- Test with Facebook Debugger
- Check Twitter Card validator

## Continuous Optimization

### Weekly Tasks
- [ ] Review PageSpeed Insights scores
- [ ] Check Core Web Vitals trends
- [ ] Monitor cache performance
- [ ] Review error logs

### Monthly Tasks
- [ ] Audit unused CSS/JS
- [ ] Optimize database queries
- [ ] Review and update image formats
- [ ] Test new performance features

### Quarterly Tasks
- [ ] Full performance audit
- [ ] Update performance benchmarks
- [ ] Review and optimize caching strategy
- [ ] Update this documentation

## Additional Resources

- [Google PageSpeed Insights](https://pagespeed.web.dev/)
- [Core Web Vitals](https://web.dev/vitals/)
- [Rails Caching Guide](https://guides.rubyonrails.org/caching_with_rails.html)
- [Image Optimization Guide](https://web.dev/fast/#optimize-your-images)
- [Performance Budget Calculator](https://www.performancebudget.io/)

## Support

For performance-related issues or questions:
1. Check this documentation
2. Review application logs
3. Test in staging environment
4. Contact the development team

Remember: Performance is a feature, not an afterthought!
