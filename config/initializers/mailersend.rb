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
        html_body = nil
        text_body = nil

        if mail.multipart?
          # Multipart email - extract HTML and text parts
          html_body = mail.html_part&.body&.to_s
          text_body = mail.text_part&.body&.to_s
        else
          # Single part email - determine type by content type
          if mail.content_type&.include?("text/html")
            html_body = mail.body.to_s
          elsif mail.content_type&.include?("text/plain")
            text_body = mail.body.to_s
          else
            # Fallback - treat as text
            text_body = mail.body.to_s
          end
        end

        # Create email object
        email = Mailersend::Email.new(client)
        email.add_from({ email: from_email, name: from_name })
        email.add_recipients({ "email" => to })
        email.add_subject(subject)

        # Add content based on what's available
        if html_body.present?
          email.add_html(html_body)
        end
        if text_body.present?
          email.add_text(text_body)
        end

        # Ensure we have at least one content type
        unless html_body.present? || text_body.present?
          Rails.logger.warn "No content found for email to #{to}, using fallback text"
          email.add_text("Email content not available")
        end

        # Send email
        response = email.send
        Rails.logger.info "MailerSend email sent successfully to #{to}"
        Rails.logger.info "MailerSend response: #{response.inspect}"
        response
      rescue => e
        Rails.logger.error "MailerSend delivery failed: #{e.message}"
        raise e
      end
    end
  end

  # Resolve API token from ENV (prefer KEY, fallback to TOKEN)
  mailersend_api_token = ENV["MAILERSEND_API_KEY"].presence || ENV["MAILERSEND_API_TOKEN"]

  # Configure MailerSend delivery method
  ActionMailer::Base.add_delivery_method :mailersend, MailerSendDeliveryMethod, {
    api_key: mailersend_api_token,
    domain: ENV.fetch("MAILERSEND_DOMAIN", "devv.me"),
    from_name: ENV.fetch("MAILERSEND_FROM_NAME", "Devv.me"),
    from_email: ENV.fetch("MAILERSEND_FROM_EMAIL", "noreply@devv.me")
  }

  # Set the delivery method for ActionMailer
  ActionMailer::Base.delivery_method = :mailersend
end
