# MailerSend configuration for Rails ActionMailer
# This initializer sets up MailerSend as a delivery method for ActionMailer

if Rails.env.production? || ENV["MAILERSEND_DEVELOPMENT"] == "true"
  require "mailersend-ruby"

  # Create a custom MailerSend delivery method
  class MailerSendDeliveryMethod
    def initialize(settings)
      @settings = settings
    end

    def deliver!(mail)
      begin
        client = Mailersend::Client.new(@settings[:api_key])

        # Extract email details
        to = mail.to.is_a?(Array) ? mail.to.first : mail.to
        from_email = @settings[:from_email]
        from_name = @settings[:from_name]
        subject = mail.subject

        # Get email body (prefer HTML, fallback to text)
        body = mail.html_part&.body&.to_s || mail.text_part&.body&.to_s || mail.body.to_s

        # Create email object
        email = Mailersend::Email.new
        email.set_from(from_email, from_name)
        email.set_recipients([{ email: to }])
        email.set_subject(subject)
        email.set_html(body)

        # Send email
        response = client.send(email)
        Rails.logger.info "MailerSend email sent successfully to #{to}"
        response
      rescue => e
        Rails.logger.error "MailerSend delivery failed: #{e.message}"
        raise e
      end
    end
  end

  # Configure MailerSend delivery method
  ActionMailer::Base.add_delivery_method :mailersend, MailerSendDeliveryMethod, {
    api_key: ENV.fetch("MAILERSEND_API_KEY", ""),
    domain: ENV.fetch("MAILERSEND_DOMAIN", "devv.me"),
    from_name: ENV.fetch("MAILERSEND_FROM_NAME", "DevV.me"),
    from_email: ENV.fetch("MAILERSEND_FROM_EMAIL", "noreply@devv.me")
  }

  # Set the delivery method for ActionMailer
  ActionMailer::Base.delivery_method = :mailersend
end
