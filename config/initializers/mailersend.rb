# frozen_string_literal: true

require "mailersend-ruby"

# MailerSend configuration
Rails.application.configure do
  # Initialize MailerSend client
  config.mailersend_client = Mailersend::Client.new(
    ENV.fetch("MAILERSEND_API_TOKEN", "")
  )

  # Set default from email for MailerSend
  config.mailersend_from_email = ENV.fetch("MAILERSEND_FROM_EMAIL", "noreply@devv.me")
  config.mailersend_from_name = ENV.fetch("MAILERSEND_FROM_NAME", "DevV.me")
end

# Make MailerSend client available globally
Rails.application.config.after_initialize do
  MailerSendClient = Rails.application.config.mailersend_client
  MailerSendFromEmail = Rails.application.config.mailersend_from_email
  MailerSendFromName = Rails.application.config.mailersend_from_name
end
