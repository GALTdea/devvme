# Registration Control

This document explains how to temporarily disable user registration in the Devvme App.

## Overview

The application supports temporarily disabling new user registrations while maintaining a professional user experience. This is useful during maintenance periods, feature updates, or when preparing for a new phase of the application.

## How to Disable Registration

### Production Environment

Set the `DISABLE_REGISTRATION` environment variable to `true`:

```bash
export DISABLE_REGISTRATION=true
```

Or add it to your production environment configuration:

```bash
# In your production deployment
DISABLE_REGISTRATION=true
```

### Development/Test Environments

Registration is **always enabled** in non-production environments, regardless of the `DISABLE_REGISTRATION` setting. This ensures developers can continue to create test accounts during development.

## User Experience

When registration is disabled:

1. **Navigation**: The "Start Building" button changes to "Coming Soon" with a disabled appearance
2. **Home Page**: The main CTA button shows "Coming Soon" with a clock icon
3. **Registration Page**: Shows a professional "Registration Temporarily Disabled" page with:
   - Clear explanation of why registration is disabled
   - Information about upcoming improvements
   - Option to subscribe for updates
   - Link back to home page

## Implementation Details

### Controller Level
- `Users::RegistrationsController` checks registration status before `new` and `create` actions
- Renders dedicated `registration_disabled.html.erb` view when disabled

### View Level
- `ApplicationHelper#registration_enabled?` provides consistent checking across views
- Navigation and home page conditionally render registration links
- Devise shared links respect the registration status

### Environment Configuration
- Added to `config/environment.example` for reference
- Only affects production environment by default

## Testing

The feature is thoroughly tested with:

- Registration disabled/enabled states
- Environment-specific behavior
- Navigation and UI changes
- POST request blocking
- Helper method functionality

Run tests with:
```bash
bin/rails test test/integration/registration_disabled_test.rb
```

## Re-enabling Registration

To re-enable registration, simply remove or unset the environment variable:

```bash
unset DISABLE_REGISTRATION
```

Or remove it from your production environment configuration.

## Best Practices

1. **Communication**: Use the registration disabled page to communicate clearly with potential users
2. **Timeline**: Provide information about when registration will reopen
3. **Updates**: Consider adding an email signup for interested users
4. **Monitoring**: Monitor user feedback during the disabled period
5. **Gradual Rollout**: Consider gradual re-enabling if needed

## Security Notes

- This feature only affects the user interface and registration flow
- Existing users can still sign in normally
- Admin functionality remains unaffected
- No data is lost when toggling this setting
