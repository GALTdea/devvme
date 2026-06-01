# Feature Brief: Sharing and Discovery Polish Stage 5

**Status:** Draft  
**Owner:** Gustavo  
**Created:** 2026-05-30  
**Updated:** 2026-06-01  
**Related Strategy:** `docs/product/strategy-2026.md`  
**Related MVP Goal:** `docs/product/mvp-product-goal.md`  
**Decision Checklist:** `docs/features/_stage-brief-decision-checklist.md`  
**Depends On:** `docs/features/completed/project-stories-stage-1.md`, `docs/features/active/dashboard-profile-reframe-stage-2.md`, `docs/features/active/ai-project-story-assistant-stage-3.md`, `docs/features/active/promotion-assets-stage-4.md`

## Summary

Make public proof-of-work pages easier to share, then lightly polish discovery around strong project stories.

Stage 5 should complete the MVP sharing loop: a developer can publish a project story, generate a reusable asset, and share a public project or profile link that renders with useful metadata and clear proof-of-work language.

Discovery work in this stage should stay modest. Reframe existing Explore/project discovery around project stories and proof-of-work, but do not build broad directories, social feeds, ranking systems, or marketplace-style discovery.

## Smallest Successful Outcome

This stage is successful when a user can share a public project story or proof-of-work profile link and the shared URL has useful title, description, image, and preview metadata.

The simplest complete path:

1. User publishes a meaningful project story.
2. User generates or copies project-specific resume bullets if needed.
3. User opens the public project story or profile.
4. User copies/shares the public URL.
5. The shared page presents clear proof-of-work metadata and a polished public surface.

## Product Intent

The MVP stays focused on the smallest complete proof-of-work loop:

```text
One developer creates or selects one real project, turns it into one structured public story, generates one practical reusable asset, and shares one public link.
```

Stage 5 completes the share externally step without turning DevvMe into a broad social network or discovery marketplace.

The user should feel:

```text
This project story is ready to send to someone.
```

## Goals

- Improve public project story metadata for Open Graph previews, including LinkedIn, and Twitter/X cards.
- Make public project story pages and proof-of-work profiles easier to copy/share.
- Reframe existing Explore language around project stories and proof-of-work.
- Prioritize published projects with meaningful story content where possible.
- Add or polish a lightweight Featured Project Stories surface only if it can reuse existing data safely.
- Preserve existing public URLs, project/profile routes, sitemap behavior, and social image infrastructure.
- Keep owner-only controls separate from public visitor share/discovery UI.

## Required vs Optional Stage 5 Work

Required for Stage 5:

- Public project story metadata is useful and proof-of-work aligned.
- Public profile metadata remains valid and proof-of-work aligned.
- Public project/profile pages have clear copy/share behavior.
- Public cards use story overview with description fallback.
- Owner-only controls and private assets do not leak publicly.

Optional if low-risk:

- Light Explore copy updates.
- Light Explore ordering preference for meaningful project stories.
- Small Featured Project Stories section using existing data safely.

Defer if risky:

- New discovery tables.
- Editorial curation workflows.
- Ranking algorithms.
- Broad technology/topic directories.
- Social feeds.

## Non-Goals

- Do not build advanced discovery directories.
- Do not build technology/topic directory pages.
- Do not build broad Explore filters beyond light proof-of-work alignment.
- Do not build a ranking algorithm, recommendation engine, or competitive story scoring.
- Do not build a social feed.
- Do not expand follower/following into a core product loop.
- Do not build marketplace, job board, recruiter, or community features.
- Do not generate social posts, recruiter summaries, cover letters, or job-specific copy.
- Do not build public visitor AI generation UI.
- Do not replace Project Insight.
- Do not rebuild GitHub Insights.
- Do not add new database tables in Stage 5.

## Users and Permissions

- Project owners can use share/copy controls for their own public project stories and profile.
- Public visitors can view and share published public pages.
- Draft and archived projects should not become publicly discoverable.
- Public share/discovery surfaces must not reveal owner-only drafts, AI suggestions, resume bullet generation, private notes, completion guidance, or admin controls.
- Admin/super-admin behavior should follow existing admin patterns for featured/user/project moderation if touched.

## Current Behavior

Existing sharing/discovery foundations include:

- Public profiles at `/:username`.
- Public projects at `/explore/:id`.
- Public Explore index at `/explore`.
- Existing Open Graph/Twitter helper support in `ApplicationHelper`.
- Existing social sharing URL helper.
- Existing profile social card/image routes.
- Existing `share_button_controller.js` for native share/copy behavior.
- Existing sitemap route.
- Existing project `featured` and user `featured` fields.

Current gaps:

- Public project story pages may not yet have proof-of-work-specific metadata and social preview behavior.
- Explore language still reads like generic project discovery instead of proof-of-work discovery.
- Share controls may not be consistently present or centered on public project stories.
- Existing featured/project discovery behavior may not distinguish meaningful project stories from generic published projects.

## Proposed Behavior

### Sharing First

Public project story pages should have useful share metadata.

Preferred metadata:

- Title: project title plus proof-of-work/project story framing.
- Description: `project.public_story_overview` with `description` fallback.
- URL: canonical public project URL.
- Image: project thumbnail/image when available; otherwise a stable profile/site social image fallback.
- Image alt: project/story-specific alt text.
- Type: use the most appropriate existing Open Graph type; do not invent unsupported metadata.

Public profiles should continue using existing profile metadata, but copy should reinforce proof-of-work profile language where appropriate.

## Metadata Contract

For public project story pages, metadata should derive from existing data:

- `title`: project title plus DevvMe/proof-of-work framing
- `description`: `project.public_story_overview` with `project.description` fallback
- `canonical_url`: public project URL
- `og:title`: same or similar to title
- `og:description`: same or similar to description
- `og:image`: project thumbnail/image if available, otherwise existing profile/site social image fallback
- `twitter:title`: same or similar to title
- `twitter:description`: same or similar to description
- `twitter:image`: same fallback behavior as OG image

Image alt should be included where existing helper patterns support it.

### Share Controls

Public project story pages and public profiles should provide lightweight share/copy behavior.

Preferred behavior:

- Use existing native share/copy controller patterns where possible.
- Provide a clear copy/share URL action.
- Keep share controls unobtrusive and public-safe.
- Track share events only through existing analytics patterns if already available.
- Do not add a new share-tracking table in Stage 5.
- Public share controls should be generic and visitor-safe.
- Owner-specific language such as "Share your story" should only appear to the owner if owner detection already exists.
- Otherwise use neutral language like "Share this project story."

Avoid:

- Generating social post copy in Stage 5.
- Adding multi-platform posting workflows.
- Requiring sign-in to copy/share public URLs.
- Showing owner-only prompts on public pages.

### Explore / Discovery Polish

Existing Explore should be lightly reframed around proof-of-work.

Preferred behavior:

- Use "Project Stories" or proof-of-work language.
- Prefer published projects with meaningful story content in ordering or sections where practical.
- Keep existing search/filter behavior if already working.
- If Explore ordering changes are made, they should be simple and explainable.
- Prefer meaningful project stories only where it does not hide valid published projects or break existing filters/search.
- Avoid major Explore redesign.
- Avoid broad directory expansion.

Featured Project Stories may be added only as a small curated/featured section.

Featured Project Stories is optional in Stage 5. The MVP requirement is share-ready public project/profile pages. If featured story logic introduces ambiguity, moderation complexity, owner-controlled endorsement risk, or extra scope, defer it.

Decision:

- Reuse existing project fields where possible.
- Do not add a new curation table in Stage 5.
- Before treating `projects.featured` as editorial curation, implementation should confirm whether owners can set it themselves. If owner-controlled, label it neutrally or keep it as a lightweight highlight rather than an editorial endorsement.

## Data Model / Contracts

Do not add a new database migration for Stage 5.

Source of truth:

- Public project URL and route.
- Public profile URL and route.
- `projects.project_story`.
- `Project#public_story_overview`.
- Project title, description, thumbnail/images, technologies, status, featured flag.
- User display name, username, avatar/social image data.
- Existing social metadata helpers and sitemap behavior.

Storage decision:

- Stage 5 should not persist new share records, discovery records, ranking records, or preview metadata.
- Do not add a new share-tracking table in Stage 5.
- Share/copy behavior can be UI-only.
- Social preview metadata should be derived from existing project/profile data at render time.

## Apply / Save Behavior

Stage 5 should not introduce AI-generated output or review/apply flows.

Allowed user actions:

- Copy public project/profile URL.
- Use native share where available.
- Navigate to public project/profile/Explore pages.

No user action in this stage should mutate project story content, resume bullet output, GitHub-derived data, or profile fields.

## Mutation Boundaries

Allowed mutations:

- None required for the default Stage 5 implementation.
- Existing analytics/share tracking may record events only if the app already has a compatible pattern.

Forbidden mutations:

- Do not update `project_story`.
- Do not update project metadata.
- Do not update publish status.
- Do not update public profile fields.
- Do not update GitHub-derived fields.
- Do not create discovery/ranking records.
- Do not delete anything.

## UX Notes

Public sharing/discovery UI should be polished and practical.

Preferred UX:

- Public project pages should feel like share-ready proof-of-work stories.
- Share controls should be easy to find but not dominate the story.
- Explore should feel like a place to find project stories, not a generic app gallery.
- Public cards should use story overviews when present, with description fallback.
- Empty states should stay simple and avoid promising broad discovery before enough strong stories exist.

Avoid:

- Marketing-heavy hero sections.
- Completion guidance on public pages.
- Public story scores.
- Social-network language that makes follows/feed feel central.
- Owner-only edit/generation prompts on public pages.

## Dashboard / Navigation Behavior

Dashboard guidance should treat sharing as the final MVP action.

Recommended behavior:

- Share guidance appears only after the user has at least one published project story.
- Earlier actions should outrank sharing when the user still needs to create, add story context, improve with AI, publish, or generate resume bullets.
- If the user has exactly one published project story, link to that public project story.
- If the user has multiple published project stories, link to the public profile.
- If Stage 4 resume bullet generation is available and incomplete, do not let sharing erase that step; share can still be available as a secondary action.
- Dashboard guidance may treat resume bullet generation as the next MVP step after publishing, but sharing should remain available once a public project story exists.
- Do not block sharing behind resume bullet generation.

## Public vs Owner-Only Behavior

Public visitors may see:

- Published project story content.
- Public profile content.
- Public share/copy controls.
- Public Explore/featured story sections.
- GitHub-derived public evidence that is already available and visually separate.

Public visitors must not see:

- AI story suggestions.
- Resume bullet generation or generated owner-only bullets.
- Completion checklists.
- Private `promotion_notes`.
- Admin/owner edit prompts.
- Draft/archived project discovery.
- Internal evidence/debug notes.

## Testing Expectations

Tests should focus on behavior and boundaries.

Recommended tests:

- Public project metadata uses project story overview with description fallback.
- Public profile metadata remains valid and proof-of-work aligned.
- Public project/profile pages expose share/copy controls without requiring sign-in.
- Draft and archived projects do not appear on public Explore or featured surfaces.
- Owner-only guidance and AI/resume generation UI do not leak publicly.
- Explore language and cards prefer project-story summaries where present.
- Featured/Explore filtering does not expose unpublished projects.
- Sitemap/canonical behavior remains stable if touched.

No mutation tests:

- Sharing should not update project story fields.
- Sharing should not update project metadata or publish status.
- Sharing should not update GitHub-derived fields.

## Implementation Plan

1. Inspect current public project/profile metadata, social image fallbacks, share button usage, and Explore behavior.
2. Define project-story metadata helpers or presenter methods only if they reduce duplication.
3. Add or update public project Open Graph metadata, including LinkedIn previews, and Twitter/X card metadata using existing helper patterns.
4. Add or polish share/copy controls on public project story pages and profiles.
5. Reframe Explore copy and cards around project stories/proof-of-work.
6. Add a lightweight Featured Project Stories section only if it can reuse existing data safely and avoid broad discovery scope.
7. Update dashboard next-action/share links only if needed to complete the MVP loop.
8. Add targeted tests for metadata, public non-leakage, share controls, and Explore filtering.
9. Update this brief with final implementation decisions and verification results.

## Acceptance Criteria

- A published project story has useful social preview metadata.
- A public profile keeps useful social preview metadata.
- A user or visitor can copy/share a public project story URL.
- A user or visitor can copy/share a public profile URL where existing profile share controls apply.
- Explore language is aligned with project stories/proof-of-work.
- Public cards prefer project story overview when available, with description fallback.
- Draft/archived projects do not appear in public discovery surfaces.
- Owner-only AI, resume bullet, completion, private note, and admin controls do not leak publicly.
- No broad discovery directory, ranking system, social feed, marketplace, job board, or GitHub Insights rebuild is introduced.
- No new database migration is introduced.

## Verification Plan

Targeted checks:

```bash
bin/rails test test/controllers/public_projects_controller_test.rb
bin/rails test test/controllers/public_profiles_controller_test.rb
bin/rails test test/controllers/dashboard_controller_test.rb
# If JavaScript controller tests exist and are configured:
bin/rails test test/javascript/controllers/share_button_controller_test.js
```

Additional checks if Explore helpers/presenters are added:

```bash
bin/rails test test/models/project_test.rb
bin/rails test test/presenters/dashboard/proof_of_work_next_action_test.rb
```

Baseline checks before handoff:

```bash
bin/rails db:migrate:status
bin/rails test
bin/rubocop
git status --short
```

## Rollout / Revert Plan

Rollout:

- Prefer additive metadata/helper/share UI changes.
- Reuse existing public URLs.
- Reuse existing social image and share helper infrastructure.
- Keep discovery changes limited to existing Explore/featured surfaces.

Revert:

- Remove/hide share controls or featured-story sections if needed.
- Revert metadata helper/view changes.
- Existing project stories, public URLs, and user/project data remain intact.

## Decisions

- [x] Should Stage 5 prioritize sharing or discovery first?
  Decision: sharing first. Discovery polish should be lightweight and should not delay share-ready public pages.
- [x] Should Stage 5 add new discovery tables?
  Decision: no. Reuse existing project/profile data and featured fields where safe.
- [x] Should Stage 5 generate social post copy?
  Decision: no. Social post generation remains deferred.
- [x] Should public pages show owner guidance or completion state?
  Decision: no. Public surfaces should stay polished and visitor-safe.
- [x] Should Explore become a broad technology directory now?
  Decision: no. Technology/topic discovery should wait until there is enough strong project-story content.

## Decision Log

- 2026-05-30: Stage 5 is scoped to share-ready public pages and light proof-of-work discovery polish.
- 2026-05-30: Social preview metadata should be derived from existing project/profile data.
- 2026-05-30: Broad discovery, ranking, directories, social feeds, and social post generation are deferred.

## Progress

- [ ] Inspect current metadata/social/share implementation.
- [ ] Define public project metadata behavior.
- [ ] Add/polish public project share controls.
- [ ] Confirm public profile share behavior remains aligned.
- [ ] Reframe Explore around project stories.
- [ ] Decide whether existing featured project data is safe for a Featured Project Stories section.
- [ ] Add/update targeted tests.
- [ ] Update this brief with implementation decisions and verification results.
