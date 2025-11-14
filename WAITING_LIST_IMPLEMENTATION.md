# Waiting List Implementation

This document describes the waiting list feature implementation for Devv.me.

## Overview

The waiting list allows potential users to sign up for early access to the platform. Admins can then review entries and approve them, which automatically creates an invited user account and sends them an invitation email through the existing invitation system.

## Architecture

### Approach: Hybrid Model

We implemented a hybrid approach that:
- Uses a separate `WaitingListEntry` model for managing signups
- Leverages the existing User invitation system for onboarding
- Integrates seamlessly with existing admin tools and workflows

### Benefits

1. **Clean Separation**: Waiting list logic doesn't pollute the User model
2. **Leverages Existing Code**: Uses your robust invitation system (tokens, access codes, emails)
3. **Scalable**: Can easily add waiting list-specific features (referrals, priority, etc.)
4. **Admin Integration**: Works with existing AdminActivity logging and Pundit policies
5. **Smooth UX**: Users get proper invitation emails with all the security features you've built

## Components

### Database

**Table: `waiting_list_entries`**
- `email` (string, required, indexed) - User's email address
- `full_name` (string, optional) - User's full name
- `status` (integer, default: 0) - Enum: pending, invited, converted, declined
- `position` (integer) - Position in queue (auto-assigned)
- `source` (string) - Tracking parameter (e.g., 'homepage', 'direct')
- `metadata` (jsonb) - Additional data storage
- `user_id` (bigint, optional, foreign key) - Linked user after approval
- `notified_at` (datetime) - When invitation was sent
- `converted_at` (datetime) - When user claimed their account
- `created_at`, `updated_at` (timestamps)

**Indexes:**
- email, status, position, user_id, created_at

### Models

**`WaitingListEntry`**
- Validations: email format, uniqueness (scoped to pending/invited status)
- Status enum: pending (0), invited (1), converted (2), declined (3)
- Scopes: `pending`, `invited`, `converted`, `recent`, `by_position`
- Key methods:
  - `approve_and_invite!(admin:)` - Creates User, sends invitation, updates status
  - `mark_as_converted!` - Updates status when user claims account
  - `mark_as_declined!` - Marks entry as declined
- Auto-assigns position before creation
- Generates unique usernames from email or full_name

### Controllers

**`WaitingListController` (Public)**
- `new` - Shows signup form
- `create` - Creates waiting list entry
- `success` - Success page after signup
- No authentication required
- Captures source parameter for tracking

**`Admin::WaitingListController`**
- `index` - Lists all entries with filtering and search
- `show` - View individual entry details
- `approve` - Approves entry and invites user (PATCH)
- `decline` - Declines entry (PATCH)
- Requires admin authentication (Pundit)
- Logs all actions to AdminActivity

### Policies

**`Admin::WaitingListPolicy`**
- `index?`, `show?` - Any admin can view
- `approve?`, `decline?` - Admins with `can_manage_users?` permission
- `bulk_approve?`, `bulk_decline?` - Super admins only (for future features)

### Views

**Public Views:**
- `waiting_list/new.html.erb` - Beautiful signup form with benefits section
- `waiting_list/success.html.erb` - Success page with social sharing, next steps

**Admin Views:**
- `admin/waiting_list/index.html.erb` - Stats cards, filters, table view
- `admin/waiting_list/show.html.erb` - Detailed entry view with actions

### Routes

```ruby
# Public routes
get "waiting-list", to: "waiting_list#new", as: :waiting_list
post "waiting-list", to: "waiting_list#create"
get "waiting-list/success", to: "waiting_list#success", as: :waiting_list_success

# Admin routes
namespace :admin do
  resources :waiting_list, only: [:index, :show] do
    member do
      patch :approve
      patch :decline
    end
  end
end
```

## Workflow

### User Journey

1. **Signup**: User visits `/waiting-list` and submits email (+ optional name)
2. **Confirmation**: Redirected to success page explaining next steps
3. **Admin Review**: Admin reviews entry in admin panel
4. **Approval**: Admin clicks "Approve & Invite"
   - System creates User with `account_status: :invited`
   - Generates invitation token and access code
   - Sends invitation email via `InvitationEmailService`
   - Updates waiting list entry to `invited` status
5. **Claim Account**: User receives email, follows link, sets password
6. **Conversion**: Entry automatically marked as `converted`

### Admin Journey

1. **Access**: Navigate to Admin Dashboard → Waiting List
2. **Review**: View stats, filter by status, search entries
3. **Approve**: Click entry → "Approve & Invite" button
4. **Track**: View in Users section, check invitation status

## Features

### Public Features
- ✅ Clean, mobile-responsive signup form
- ✅ Email validation and duplicate prevention
- ✅ Position tracking (queue number)
- ✅ Source tracking (marketing attribution)
- ✅ Beautiful success page with social sharing
- ✅ SEO-optimized pages

### Admin Features
- ✅ Statistics dashboard (Total, Pending, Invited, Converted, Declined)
- ✅ Search by email or name
- ✅ Filter by status
- ✅ Sort by date, email, position
- ✅ Detailed entry view
- ✅ One-click approve & invite
- ✅ Activity logging
- ✅ Pagination
- ✅ Integration with existing admin navigation

### Security
- ✅ Admin-only access with Pundit policies
- ✅ CSRF protection
- ✅ SQL injection prevention
- ✅ Activity logging for audit trail
- ✅ Leverages existing invitation security (tokens, access codes)

## Testing

Comprehensive test coverage includes:

### Model Tests (`test/models/waiting_list_entry_test.rb`)
- Validations (email format, uniqueness, presence)
- Status transitions
- Position auto-assignment
- Approve and invite functionality
- Username generation
- Scopes

### Controller Tests
- `test/controllers/waiting_list_controller_test.rb` - Public signup flow
- `test/controllers/admin/waiting_list_controller_test.rb` - Admin management

### Fixtures
- `test/fixtures/waiting_list_entries.yml` - Test data

## Future Enhancements

### Recommended Additions

1. **Email Notifications**
   - Welcome email on signup
   - Invitation sent notification
   - Reminder emails

2. **Analytics**
   - Conversion rates
   - Time to conversion
   - Source attribution analysis
   - Cohort analysis

3. **Bulk Operations**
   - Bulk approve
   - Bulk decline
   - CSV export/import

4. **Gamification**
   - Referral system (move up in queue)
   - Share bonuses
   - Priority tiers

5. **Communication**
   - Send updates to waiting list
   - Segment by status
   - Custom messages

6. **Integration**
   - Connect with marketing tools (Mailchimp, etc.)
   - Webhook notifications
   - API endpoints

## Configuration

### Environment Variables

None required. The feature works out of the box.

### Optional Settings

You can customize the invitation expiry period in the User model (currently 30 days).

## Deployment Checklist

- [x] Run migrations: `bin/rails db:migrate`
- [ ] Review and customize email templates (when mailer is implemented)
- [ ] Add "Join Waiting List" links to homepage/marketing pages
- [ ] Update .env.example if adding new configuration
- [ ] Announce to team about new admin feature
- [ ] Consider adding waiting list CTA when registration is disabled

## Usage Examples

### Linking to Waiting List

```erb
<!-- From any view -->
<%= link_to "Join Waiting List", waiting_list_path, class: "btn btn-primary" %>

<!-- With tracking source -->
<%= link_to "Join Waiting List", waiting_list_path(source: 'homepage'), class: "btn" %>
```

### Checking Waiting List Stats in Code

```ruby
# In controllers or console
WaitingListEntry.pending.count
WaitingListEntry.recent.count
WaitingListEntry.where(status: :pending).by_position.first(10)
```

### Manual Approval (Console)

```ruby
entry = WaitingListEntry.pending.first
admin = User.find_by(role: :admin)
entry.approve_and_invite!(admin: admin)
```

## Maintenance

### Database Cleanup

Consider periodically archiving old converted entries:

```ruby
# Keep converted entries for 90 days then archive
WaitingListEntry.converted.where('converted_at < ?', 90.days.ago)
```

### Monitoring

Key metrics to track:
- Pending entries count
- Average time from signup to approval
- Conversion rate (invited → converted)
- Source attribution (which sources drive signups)

## Support

For questions or issues:
1. Check this documentation
2. Review the test files for usage examples
3. Consult the main invitation system docs (INVITATION_SECURITY_IMPLEMENTATION.md)

---

**Implementation Date**: November 2025  
**Version**: 1.0  
**Author**: AI Assistant


