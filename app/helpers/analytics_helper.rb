module AnalyticsHelper
  # Google Analytics configuration
  def google_analytics_id
    Rails.application.credentials.dig(:google, :analytics_id) || ENV["GOOGLE_ANALYTICS_ID"]
  end

  # Check if Google Analytics should be enabled
  def google_analytics_enabled?
    google_analytics_id.present? && Rails.env.production?
  end

  # Generate Google Analytics tracking code
  def google_analytics_tag
    return unless google_analytics_enabled?

    content_tag :script, async: true, src: "https://www.googletagmanager.com/gtag/js?id=#{google_analytics_id}" do
    end +
    content_tag(:script, type: "text/javascript") do
      raw <<~JAVASCRIPT
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', '#{google_analytics_id}', {
          page_title: document.title,
          page_location: window.location.href
        });
      JAVASCRIPT
    end
  end

  # Track custom events
  def track_event(event_name, parameters = {})
    return unless google_analytics_enabled?

    content_tag(:script, type: "text/javascript") do
      raw <<~JAVASCRIPT
        if (typeof gtag !== 'undefined') {
          gtag('event', '#{event_name}', #{parameters.to_json});
        }
      JAVASCRIPT
    end
  end

  # Track profile view event
  def track_profile_view(username, user_id)
    track_event("profile_view", {
      event_category: "engagement",
      event_label: username,
      user_id: user_id,
      custom_parameter_1: "profile_visit"
    })
  end

  # Track social sharing
  def track_social_share(platform, url)
    track_event("share", {
      event_category: "social",
      event_label: platform,
      value: url
    })
  end

  # Track download events (resume, etc.)
  def track_download(file_type, filename)
    track_event("file_download", {
      event_category: "downloads",
      event_label: file_type,
      value: filename
    })
  end
end
