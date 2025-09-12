class ApplicationMailer < ActionMailer::Base
  default from: "noreply@devv.me"
  layout "mailer"

  # Override the deliver method to use MailerSend
  def deliver_now
    if Rails.env.development? && Rails.application.config.action_mailer.delivery_method == :letter_opener
      # Use letter_opener in development
      super
    else
      # Use MailerSend for production and when not using letter_opener
      deliver_with_mailersend
    end
  end

  def deliver_later(options = {})
    if Rails.env.development? && Rails.application.config.action_mailer.delivery_method == :letter_opener
      # Use letter_opener in development
      super
    else
      # Use MailerSend for production and when not using letter_opener
      deliver_with_mailersend
    end
  end

  private

  def deliver_with_mailersend
    return unless MailerSendClient

    begin
      # Initialize MailerSend email
      email = Mailersend::Email.new(MailerSendClient)

      # Set from address
      email.add_from(
        email: MailerSendFromEmail,
        name: MailerSendFromName
      )

      # Set recipients
      if mail.to.present?
        mail.to.each do |recipient|
          email.add_recipients(email: recipient)
        end
      end

      # Set CC recipients
      if mail.cc.present?
        mail.cc.each do |recipient|
          email.add_cc(email: recipient)
        end
      end

      # Set BCC recipients
      if mail.bcc.present?
        mail.bcc.each do |recipient|
          email.add_bcc(email: recipient)
        end
      end

      # Set subject
      email.add_subject(mail.subject) if mail.subject.present?

      # Set HTML content
      if mail.html_part.present?
        email.add_html(mail.html_part.body.to_s)
      elsif mail.content_type&.include?("text/html")
        email.add_html(mail.body.to_s)
      end

      # Set text content
      if mail.text_part.present?
        email.add_text(mail.text_part.body.to_s)
      elsif mail.content_type&.include?("text/plain")
        email.add_text(mail.body.to_s)
      end

      # Set reply-to if present
      if mail.reply_to.present?
        email.add_reply_to(email: mail.reply_to.first)
      end

      # Send the email
      response = email.send

      Rails.logger.info "MailerSend email sent successfully: #{response}"
      response
    rescue StandardError => e
      Rails.logger.error "MailerSend delivery failed: #{e.message}"
      raise e
    end
  end
end
