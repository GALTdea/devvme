# MailerSend Integration Setup

This document outlines the setup and configuration for MailerSend email service integration in your Rails application.

## Required Environment Variables

### For Production (Hatchbox.ai)

Set these environment variables in your Hatchbox deployment:

```bash
# MailerSend Configuration
MAILERSEND_API_TOKEN=your_mailersend_api_token_here
MAILERSEND_FROM_EMAIL=noreply@devv.me
MAILERSEND_FROM_NAME=DevV.me

# Rails Mailer Configuration
RAILS_MAILER_RAISE_DELIVERY_ERRORS=true
RAILS_MAILER_PERFORM_DELIVERIES=true
RAILS_HOST=devv.me
```

### For Development

Create a `.env` file in your project root (or add to your existing environment setup):

```bash
# MailerSend Configuration (optional for development)
MAILERSEND_API_TOKEN=your_mailersend_api_token_here
MAILERSEND_FROM_EMAIL=noreply@devv.me
MAILERSEND_FROM_NAME=DevV.me

# Use MailerSend in development (set to true to test real emails)
MAILERSEND_DEVELOPMENT=false
```

## Getting Your MailerSend API Token

1. Sign up for a MailerSend account at [mailersend.com](https://mailersend.com)
2. Go to your dashboard and navigate to "API Tokens"
3. Create a new API token with the following permissions:
   - Email: Send emails
   - Email: Read email activity
   - Email: Read email logs
4. Copy the generated token and use it as `MAILERSEND_API_TOKEN`

## Domain Verification

1. In your MailerSend dashboard, go to "Domains"
2. Add your domain `devv.me`
3. Follow the DNS verification steps to verify domain ownership
4. Once verified, you can use `noreply@devv.me` as your from address

## Development vs Production Behavior

### Development Environment
- **Default**: Uses `letter_opener` to preview emails in the browser
- **With MailerSend**: Set `MAILERSEND_DEVELOPMENT=true` to send real emails via MailerSend

### Production Environment
- **Always uses MailerSend** for sending emails
- Requires all MailerSend environment variables to be set

## Testing the Integration

### In Development

1. **Test with letter_opener (default)**:
   ```bash
   # Start your Rails server
   bin/rails server
   
   # In another terminal, open Rails console
   bin/rails console
   
   # Send a test email
   user = User.first
   UserWelcomeMailer.welcome_notification(user).deliver_now
   ```

2. **Test with MailerSend**:
   ```bash
   # Set environment variable
   export MAILERSEND_DEVELOPMENT=true
   
   # Start your Rails server
   bin/rails server
   
   # In another terminal, open Rails console
   bin/rails console
   
   # Send a test email
   user = User.first
   UserWelcomeMailer.welcome_notification(user).deliver_now
   ```

### In Production

After deploying to Hatchbox with the required environment variables:

```bash
# SSH into your production server or use Hatchbox console
bin/rails console

# Send a test email
user = User.first
UserWelcomeMailer.welcome_notification(user).deliver_now
```

## Troubleshooting

### Common Issues

1. **"MailerSend delivery failed" errors**:
   - Check that `MAILERSEND_API_TOKEN` is set correctly
   - Verify your domain is verified in MailerSend dashboard
   - Check that `MAILERSEND_FROM_EMAIL` matches a verified domain

2. **Emails not being sent in development**:
   - Ensure `MAILERSEND_DEVELOPMENT=true` is set
   - Check that all required environment variables are present

3. **Emails not being sent in production**:
   - Verify all environment variables are set in Hatchbox
   - Check Rails logs for error messages
   - Ensure your MailerSend account has sufficient credits

### Logging

MailerSend integration includes comprehensive logging:
- Successful sends are logged with response details
- Failed sends are logged with error messages
- Check your Rails logs for detailed information

## Security Notes

- Never commit your `MAILERSEND_API_TOKEN` to version control
- Use environment variables for all sensitive configuration
- Regularly rotate your API tokens
- Monitor your MailerSend usage and billing

## Support

- MailerSend Documentation: [developers.mailersend.com](https://developers.mailersend.com)
- MailerSend Support: info@mailersend.com
- Ruby SDK: [github.com/mailersend/mailersend-ruby](https://github.com/mailersend/mailersend-ruby)
