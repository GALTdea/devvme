# Featured Profiles Implementation

## Overview
A simple, admin-curated featured profiles section has been implemented for the homepage. Super admins can manually select which users to feature, and these profiles will be displayed in a prominent section on the homepage.

## What Was Implemented

### 1. Database Changes
- **Migration**: Added `featured` (boolean, default: false) and `featured_at` (datetime) columns to the `users` table
- **Index**: Added an index on the `featured` column for performance

### 2. User Model (`app/models/user.rb`)
- **Scope**: Added `featured` scope to query featured users
- **Method**: Added `toggle_featured!(admin:)` method to toggle feature status and track when users were featured
- Logs admin activity when users are featured/unfeatured

### 3. Admin Controller (`app/controllers/admin/users_controller.rb`)
- **Action**: Added `toggle_featured` action to toggle a user's featured status
- Only accessible by super admins (uses existing authorization)
- Redirects back to user show page with success message

### 4. Routes (`config/routes.rb`)
- Added `patch :toggle_featured` to admin users member routes

### 5. Admin User Show View (`app/views/admin/users/show.html.erb`)
- Added "Feature User" / "Unfeature User" button in the Actions sidebar
- Only visible to super admins
- Shows when the user was featured if currently featured
- Visual distinction with amber/gold styling for featured status

### 6. Home Controller (`app/controllers/home_controller.rb`)
- Fetches up to 10 featured users with:
  - Valid username (not nil)
  - Active or invited status
  - Random order (changes on each page load)

### 7. Home View (`app/views/home/index.html.erb`)
- Replaced static placeholder cards with dynamic featured user cards
- Each card shows:
  - User avatar or generated initials with gradient background
  - Display name and headline/job title
  - Bio (truncated to 2 lines)
  - Follower count
  - Project count (if they have published projects)
- Cards link to the user's public profile
- Fragment caching for performance
- Fallback message if no featured users exist

## How To Use

### For Super Admins

#### Method 1: Quick Toggle from User Index (Recommended)

1. **Navigate to Admin Panel**: Go to `/admin/users`
2. **See Featured Users**: 
   - View the "Featured" stat card showing current count
   - Filter to show only featured users using the "Featured Only" dropdown
3. **Toggle Featured Status**:
   - Click the star icon (⭐) in the "Featured" column for any user
   - Gold star = currently featured (click to unfeature)
   - Gray star = not featured (click to feature)
   - Confirm the action in the popup

#### Method 2: From User Detail Page

1. **Navigate to Admin Panel**: Go to `/admin/users`
2. **Select a User**: Click on any user to view their profile
3. **Feature the User**: 
   - Scroll to the "Actions" section in the sidebar
   - Click the "⭐ Feature User" button
   - Confirm the action
4. **Unfeature a User**:
   - On a featured user's profile, click "⭐ Unfeature User"
   - Confirm the action

### Best Practices

- **Quality Control**: Only feature users with:
  - Complete profiles (avatar, bio, headline)
  - Published projects or blog posts
  - Active account status
  - Good content quality

- **Diversity**: Consider featuring users with:
  - Different tech stacks and specializations
  - Varied experience levels
  - Geographic diversity

- **Rotation**: Periodically review and rotate featured users to:
  - Showcase new talent
  - Keep the homepage fresh
  - Give different users exposure

- **Limit**: While the system supports up to 10 featured users, consider starting with 4-8 for better visual impact

## Technical Details

### Performance
- Featured users query is optimized with index on `featured` column
- Fragment caching on homepage with cache key based on:
  - Featured users count
  - Maximum updated_at timestamp
- Cache automatically expires when:
  - A user is featured/unfeatured
  - Featured user updates their profile

### Random Order
- Uses `order("RANDOM()")` for PostgreSQL
- Different selection shown on each page load
- Ensures all featured users get exposure over time

### Security
- Only super admins can feature/unfeature users
- Uses existing Pundit authorization
- Admin activity is logged for audit trail

## Future Enhancements (Optional)

If needed in the future, consider:
- Manual ordering/priority for featured users
- Featured duration (auto-expire after X days)
- Analytics on featured profile click-through rates
- Opt-in system for users to consent to being featured
- Featured profile badges on user profiles
- Email notifications when users are featured

## Admin Index View Features (Added)

The admin users index page now includes featured profile management:

### 1. Featured Users Stat Card
- Shows total count of featured users
- Only visible to super admins
- Uses amber/gold styling with star icon

### 2. Featured Filter
- Dropdown filter to show "All Users" or "Featured Only"
- Only visible to super admins
- Integrates with existing filter system

### 3. Featured Column
- Table column showing featured status with star icons
- Gold filled star (⭐) = featured
- Gray outlined star = not featured  
- Click to toggle status instantly
- Only visible to super admins

### 4. Quick Toggle
- One-click feature/unfeature from the index
- Confirmation dialog for safety
- Instant visual feedback
- Much faster than going to user detail page

## Files Modified

1. `db/migrate/20251010193917_add_featured_to_users.rb` (new)
2. `app/models/user.rb`
3. `app/controllers/admin/users_controller.rb` (updated with filter logic and count)
4. `app/controllers/home_controller.rb`
5. `app/views/admin/users/show.html.erb`
6. `app/views/admin/users/index.html.erb` (updated with featured column and filter)
7. `app/views/home/index.html.erb`
8. `config/routes.rb`

