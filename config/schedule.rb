# Use this file to define periodic tasks executed with cron
# Learn more: http://github.com/javan/whenever

# Clean up old social images weekly (every Monday at 2 AM)
every 1.week, at: "2:00 am" do
  rake "social_images:cleanup"
end
