# MailerSend configuration for Rails ActionMailer
# This initializer sets up MailerSend as a delivery method for ActionMailer

if Rails.env.production? || ENV["MAILERSEND_DEVELOPMENT"] == "true"
  require "mailersend-ruby"

  # Configure MailerSend delivery method
  ActionMailer::Base.add_delivery_method :mailersend, MailerSend::DeliveryMethod, {
    api_key: ENV.fetch("MAILERSEND_API_KEY", ""),
    domain: ENV.fetch("MAILERSEND_DOMAIN", "devv.me"),
    from_name: ENV.fetch("MAILERSEND_FROM_NAME", "DevV.me"),
    from_email: ENV.fetch("MAILERSEND_FROM_EMAIL", "noreply@devv.me")
  }

  # Set the delivery method for ActionMailer
  ActionMailer::Base.delivery_method = :mailersend
end
