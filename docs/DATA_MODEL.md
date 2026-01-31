# Data Model Overview

One-page reference for main entities and relationships. Canonical schema: `db/schema.rb`.

## Core entities

### User (`users`)
- **Auth**: Devise (email, encrypted_password). Slug from **FriendlyId** (username).
- **Enums**: `role` (user, admin, super_admin), `account_status` (pending_activation, invited, active, suspended, deactivated).
- **Invitation**: invitation_token, invitation_sent_at, invitation_accepted_at, invitation_access_code.
- **Profile**: full_name, bio, headline, job_title, location, skills (json), work_preferences (jsonb), open_for_work, social links, avatar/resume (Active Storage).
- **Admin**: suspended_at, suspension_reason, admin_notes; featured, featured_at.
- **Associations**: has_many projects, blog_posts, profile_views, admin_activities (as admin), visitors (optional), user_digest_preferences; followers/following via Follow; notifications (Noticed, as recipient).

### BlogPost (`blog_posts`)
- **Owner**: belongs_to user.
- **Slug**: FriendlyId from title.
- **Content**: content (text), excerpt; has_rich_text :content_html (Action Text). `editor_mode`: markdown | rich_text.
- **State**: published (boolean), published_at, archived, featured; views_count.
- **Scopes**: published, draft, archived, featured, by_publication_date, by_popularity.

### Project (`projects`)
- **Owner**: belongs_to user.
- **Fields**: title, description, technologies_used (json array), live_url, source_code_url (or legacy github_url, demo_url), status, display_order, featured.
- **Attachments**: has_many_attached :images, has_one_attached :thumbnail (Active Storage).
- **Enum**: status (draft, published, archived).

### Follow (`follows`)
- **Relationship**: follower_id, followee_id (both → users). Unique on [follower_id, followee_id].
- **User side**: user has_many active_follows (as follower), passive_follows (as followee); following / followers through Follow.

---

## Analytics & tracking

### Visitor (`visitors`)
- **Identity**: visitor_id (unique), ip_address, user_agent, referrer, country, city.
- **Metrics**: first_visit_at, last_visit_at, last_activity_at, visit_count, page_views, total_time_on_site.
- **Conversion**: converted (boolean); user_id (optional, set when visitor signs up).
- **Associations**: has_many visitor_page_views; belongs_to user (optional).

### VisitorPageView (`visitor_page_views`)
- **Parent**: belongs_to visitor.
- **Fields**: page_path, page_title, referrer, time_on_page, viewed_at.

### ProfileView (`profile_views`)
- **Target**: belongs_to user.
- **Fields**: visitor_ip, user_agent, referrer, visited_at.
- **Use**: Profile view analytics per user.

---

## User preferences & notifications

### UserDigestPreference (`user_digest_preferences`)
- **Owner**: belongs_to user (one per user).
- **Settings**: frequency (enum), enabled, include_blog_posts, include_projects, include_profile_updates.
- **Scheduling**: digest_time, timezone, last_sent_at, next_send_at.
- **Use**: Email digest for followed users’ activity.

### Noticed
- **noticed_events**: type, record_type, record_id, params (jsonb), notifications_count.
- **noticed_notifications**: type, event_id, recipient_type, recipient_id, read_at, seen_at.
- **Use**: In-app and/or email notifications; recipient is usually User.

---

## Admin & audit

### AdminActivity (`admin_activities`)
- **Actor**: admin_id → users.
- **Target**: target_type, target_id (polymorphic); action (string); details (json); ip_address, user_agent.
- **Use**: Audit log for admin actions.

---

## Career Architect (AI profile builder)

### ArchitectSession (`architect_sessions`)
- **Owner**: belongs_to user.
- **State**: status (draft, in_progress, completed, abandoned); goal (bio, headline, both).
- **Context**: context_snapshot (jsonb) — profile + projects + pasted content for LLM.
- **Output**: generated_bio (text), generated_headline (text); question_count (integer).
- **Associations**: has_many architect_messages.
- **Use**: One Career Architect flow per session; user answers Socratic Q&A then accepts or discards generated bio/headline.

### ArchitectMessage (`architect_messages`)
- **Parent**: belongs_to architect_session.
- **Fields**: role (user | assistant), content (text), sequence (integer); topic, insight_type, metadata (jsonb) for future training/analytics.
- **Use**: Conversation history for Q&A; max 20 messages per session (ArchitectService::MAX_QA_MESSAGES).

---

## Rails / third-party tables (reference only)

- **action_text_rich_texts**: Action Text rich text (e.g. BlogPost content_html).
- **active_storage_***: Active Storage (attachments, blobs, variant_records).
- **friendly_id_slugs**: FriendlyId slug history (User, BlogPost).
