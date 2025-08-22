module PerformanceHelper
  # Add performance monitoring scripts
  def performance_monitoring_scripts
    return unless Rails.env.production?

    scripts = []

    # Core Web Vitals monitoring
    scripts << content_tag(:script, type: "module") do
      raw <<~JAVASCRIPT
        import {getCLS, getFID, getFCP, getLCP, getTTFB} from 'https://unpkg.com/web-vitals?module';

        function sendToAnalytics(metric) {
          // Send to Google Analytics if available
          if (typeof gtag !== 'undefined') {
            gtag('event', metric.name, {
              event_category: 'Web Vitals',
              event_label: metric.id,
              value: Math.round(metric.name === 'CLS' ? metric.value * 1000 : metric.value),
              non_interaction: true,
            });
          }

          // Also log to console in development
          console.log('Core Web Vital:', metric.name, Math.round(metric.value), metric.rating);
        }

        // Measure and report Core Web Vitals
        getCLS(sendToAnalytics);
        getFID(sendToAnalytics);
        getFCP(sendToAnalytics);
        getLCP(sendToAnalytics);
        getTTFB(sendToAnalytics);
      JAVASCRIPT
    end

    # Performance observer for monitoring
    scripts << content_tag(:script) do
      raw <<~JAVASCRIPT
        // Performance monitoring
        if ('PerformanceObserver' in window) {
          // Monitor Long Tasks (> 50ms)
          const longTaskObserver = new PerformanceObserver((list) => {
            for (const entry of list.getEntries()) {
              if (typeof gtag !== 'undefined') {
                gtag('event', 'long_task', {
                  event_category: 'Performance',
                  event_label: 'Task Duration',
                  value: Math.round(entry.duration),
                  non_interaction: true,
                });
              }
            }
          });

          try {
            longTaskObserver.observe({entryTypes: ['longtask']});
          } catch (e) {
            // Long Task API not supported
          }

          // Monitor Navigation Timing
          const navigationObserver = new PerformanceObserver((list) => {
            for (const entry of list.getEntries()) {
              if (typeof gtag !== 'undefined') {
                gtag('event', 'navigation_timing', {
                  event_category: 'Performance',
                  event_label: 'Page Load',
                  value: Math.round(entry.loadEventEnd - entry.navigationStart),
                  non_interaction: true,
                });
              }
            }
          });

          try {
            navigationObserver.observe({entryTypes: ['navigation']});
          } catch (e) {
            // Navigation Timing API not supported
          }
        }
      JAVASCRIPT
    end

    safe_join(scripts, "\n")
  end

  # Resource hints for better performance
  def performance_resource_hints
    hints = []

    # DNS prefetch for external resources
    external_domains = [
      "fonts.googleapis.com",
      "fonts.gstatic.com",
      "www.googletagmanager.com",
      "www.google-analytics.com",
      "cdn.jsdelivr.net",
      "unpkg.com"
    ]

    external_domains.each do |domain|
      hints << tag.link(rel: "dns-prefetch", href: "//#{domain}")
    end

    # Preconnect to critical external resources
    critical_domains = [
      "fonts.googleapis.com",
      "fonts.gstatic.com"
    ]

    critical_domains.each do |domain|
      hints << tag.link(rel: "preconnect", href: "https://#{domain}", crossorigin: true)
    end

    # Preload critical CSS
    hints << tag.link(rel: "preload", href: asset_path("application.css"), as: "style")

    safe_join(hints, "\n")
  end

  # Critical CSS inlining for above-the-fold content
  def critical_css
    # This would contain the critical CSS for above-the-fold content
    # In a real implementation, you'd extract this from your main CSS file
    content_tag(:style) do
      raw <<~CSS
        /* Critical CSS for above-the-fold content */
        body {
          font-family: 'Inter', sans-serif;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 1280px;
          margin: 0 auto;
          padding: 0 1rem;
        }
        /* Add more critical styles here */
      CSS
    end
  end

  # Performance metrics tracking
  def track_performance_metrics
    return unless Rails.env.production?

    content_tag(:script) do
      raw <<~JAVASCRIPT
        // Track page load performance
        window.addEventListener('load', function() {
          setTimeout(function() {
            if (performance.timing) {
              const timing = performance.timing;
              const loadTime = timing.loadEventEnd - timing.navigationStart;
              const domReady = timing.domContentLoadedEventEnd - timing.navigationStart;
              const firstPaint = performance.getEntriesByType('paint')[0]?.startTime || 0;

              // Send to analytics
              if (typeof gtag !== 'undefined') {
                gtag('event', 'page_performance', {
                  event_category: 'Performance',
                  event_label: 'Load Time',
                  value: Math.round(loadTime),
                  custom_parameter_1: Math.round(domReady),
                  custom_parameter_2: Math.round(firstPaint)
                });
              }
            }
          }, 100);
        });
      JAVASCRIPT
    end
  end
end
