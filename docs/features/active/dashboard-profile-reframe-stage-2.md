# Feature Brief: Dashboard and Profile Reframe Stage 2

**Status:** Implemented  
**Owner:** Gustavo  
**Created:** 2026-05-29  
**Updated:** 2026-05-29  
**Related Strategy:** `docs/product/strategy-2026.md`  
**Related MVP Goal:** `docs/product/mvp-product-goal.md`  

## Summary

Reframe the signed-in dashboard and public profile around DevvMe's proof-of-work MVP loop.

Stage 1 established project stories as the core content structure. Stage 2 should make the product feel like a proof-of-work platform from the first signed-in moment and from the public profile surface. The user should be guided toward creating, improving, publishing, and sharing project stories without needing to understand every existing DevvMe feature.

This is a focused product-language, prioritization, and UI hierarchy pass. It is not a full dashboard/profile redesign.

## Product Intent

The MVP stays focused on the smallest complete proof-of-work loop:

```text
One developer creates or selects one real project, turns it into one structured public story, generates one practical reusable asset, and shares one public link.
```

Stage 2 supports that loop by making the app point users toward their next best proof-of-work action.

The dashboard should answer:

- What should I do next to turn my work into public proof?
- Which projects need better story context?
- Which project stories are published and shareable?

The public profile should answer:

- What work has this developer actually done?
- Which project stories best prove their skills?
- Where can I read the clearest proof-of-work?

## Goals

- Reframe dashboard language from generic portfolio management toward proof-of-work and project stories.
- Add dashboard next-step guidance for creating, completing, publishing, or sharing project stories.
- Introduce lightweight story completeness guidance without judgmental scoring.
- Reframe public profile project presentation around project stories as the main proof surface.
- Reduce the visual/product prominence of secondary blog, follow, network, and digest surfaces where they compete with the MVP loop.
- Preserve existing routes, data, public URLs, and user workflows.

## Non-Goals

- Do not redesign the entire dashboard from scratch.
- Do not redesign every public profile section.
- Do not remove blog, follows, network, analytics, or digest functionality.
- Do not implement AI Project Story Builder in this stage.
- Do not implement resume bullet generation in this stage.
- Do not create broad discovery, featured story, directory, marketplace, job board, or social network features.
- Do not introduce judgmental story scoring.

## Users and Permissions

- Signed-in users see dashboard guidance for their own projects and profile.
- Public visitors see published project stories on public profiles.
- Existing account status, ownership, visibility, and authorization behavior must remain intact.
- Admin/super-admin behavior is out of scope except where existing shared profile/project rendering is reused.

## Current Behavior

Current dashboard behavior still reflects the earlier product shape:

- It welcomes users to their "developer portfolio."
- It surfaces project, blog, view, and profile completion metrics together.
- Blog stats and network/digest surfaces can compete with project-story work.
- Profile completion is profile-oriented rather than proof/story-oriented.
- Recent projects exist, but the page does not clearly guide a user toward project-story completion or sharing.

Current public profile behavior:

- Public profiles include profile header, stats, projects, and blog sections.
- Projects are visible, but the profile is not yet explicitly organized around project stories as proof-of-work.

Relevant existing areas likely include:

- `app/controllers/dashboard_controller.rb`
- `app/views/dashboard/index.html.erb`
- `app/controllers/public_profiles_controller.rb`
- `app/views/public_profiles/show.html.erb`
- `app/views/public_profiles/_projects_section.html.erb`
- `app/views/public_profiles/_public_project_card.html.erb`
- `app/views/public_profiles/_blog_posts_section.html.erb`
- `app/views/public_profiles/_profile_stats.html.erb`
- `app/models/concerns/project_story.rb`
- `test/controllers/dashboard_controller_test.rb`
- `test/controllers/public_profiles_controller_test.rb`
- `test/system/unclaimed_profile_ui_test.rb`

## Proposed Behavior

### Dashboard

The signed-in dashboard should prioritize proof-of-work actions.

The primary dashboard area should guide the user toward one next action:

- Create a project story if they have no projects.
- Add story context if they have projects without useful story fields.
- Publish a story if they have drafted/unpublished project stories.
- Share a public project story if they have at least one published story.

The dashboard should make project stories feel more important than blog/network activity.

Recommended language direction:

- "Turn your work into proof"
- "Project stories"
- "Your proof-of-work profile"
- "Make this project easier to explain"
- "Share this story"

Avoid overusing:

- "Portfolio completion"
- "Content performance"
- "Network growth"
- "Social feed"

## Next Action Priority Rules

The dashboard should choose one primary next action using this priority order:

1. If the user has no projects:
   - CTA: "Create your first project story"
   - Supporting copy: "Start with one real project you've built. DevvMe will help you turn it into clear proof-of-work."

2. If the user has projects but no project has meaningful story content:
   - CTA: "Add story context"
   - Supporting copy: "Help visitors understand what you built, why it matters, and what it demonstrates."

3. If the user has at least one draft/unpublished project story with meaningful story content:
   - CTA: "Publish your project story"
   - Supporting copy: "Your story has enough context to become public proof-of-work."

4. If the user has published projects but none have meaningful story content:
   - CTA: "Improve your published story"
   - Supporting copy: "Your project is public, but it needs more context to become strong proof-of-work."

5. If the user has exactly one published project with meaningful story content:
   - CTA: "Share your project story"
   - Supporting copy: "Your work is ready to share with recruiters, peers, clients, or collaborators."

6. If the user has multiple published projects with meaningful story content:
   - CTA: "Share your proof-of-work profile"
   - Supporting copy: "Your profile now has multiple proof points. Share the full profile to show the range of your work."
   - Secondary CTA may be: "Improve your strongest story."

### Story Completeness Guidance

Use a lightweight checklist, not a numerical or competitive score.

Minimum useful signal:

- Overview
- Problem
- Role
- Challenge
- Lesson
- Demonstration statement

Good example:

```text
Your story has 3 of 6 helpful sections.
```

Avoid:

```text
Your story score is 47/100.
```

Completeness should be guidance, not judgment. It should not block saving or publishing in Stage 2.

## Meaningful Story Content

For Stage 2, a project has meaningful story content if at least two of the six core story sections are present.

Core sections:

- Overview
- Problem
- Role
- Challenge
- Lesson
- Demonstration statement

Core section field mapping:

- Overview -> `project_story["overview"]`
- Problem -> `project_story["problem"]`
- Role -> `project_story["role"]`
- Challenge -> `project_story["hardest_challenge"]`
- Lesson -> `project_story["lessons_learned"]`
- Demonstration statement -> `project_story["demonstrates"]`

This threshold is intentionally low. It is only used to guide next actions, not to judge quality or block publishing.

For Stage 2, a "published project story" means a published project that has meaningful story content. A published project without meaningful story content should be treated as a published project that needs story improvement.

### Public Profile

The public profile should present project stories as the strongest proof surface.

The project section should:

- Use "Project Stories" or similar proof-of-work language.
- Prioritize published projects with story content where possible.
- Make story-oriented summaries visible when available.
- Preserve existing public profile URLs and project links.
- Keep blog content secondary unless it directly supports proof-of-work.
- Keep project cards skimmable. They should not become long-form story pages.
- When available, cards may use the project story overview as the preferred summary, with the existing description as fallback.

## Owner vs Public Visitor Behavior

Owner-facing guidance belongs on the dashboard and project edit/manage surfaces.

Public profile visitors should see polished proof-of-work content, not completion checklists, editing prompts, or instructional UI.

Do not show story completeness counts on public profiles.

## Data Model / Contracts

No new database tables are expected for Stage 2.

Preferred approach:

- Reuse `projects.project_story`.
- Add model/controller helper methods only if they simplify story completeness and next-action logic.
- Keep story completeness derived from existing project story fields.
- Do not persist a story score.

Preferred helper behavior:

- `Project#story_completion_sections` returns the core sections and whether each is present.
- `Project#story_completion_count` returns completed core sections count.
- `Project#story_completion_total` returns total core sections count.
- `Project#story_meaningful?` returns true when at least two core sections are present.
- `Project#story_complete_enough_to_share?` may return true when the project is published and has meaningful story content.

Prefer a dashboard presenter/helper for next-action logic if the implementation becomes more than a few lines. Keep the `Project` model responsible only for project-level story completeness helpers.

## UX Notes

Dashboard UI should be practical and action-oriented.

Preferred shape:

- A top proof-of-work guidance panel.
- A compact project-story status area.
- Clear CTAs for the next step.
- Existing analytics/blog/network sections demoted lower on the page or visually reduced.

Public profile UI should remain public-facing and polished:

- Avoid dense admin/dashboard language.
- Keep project story cards readable and skimmable.
- Keep project cards concise; public profile cards should link to long-form project story pages instead of becoming long-form story pages themselves.
- Prefer project story overview as card summary when available, with existing description as fallback.
- Do not add in-app instructional copy that public visitors do not need.

Empty states should be encouraging and concrete:

- No projects: guide user to create their first project story.
- Projects without story fields: guide user to add story context.
- Draft stories: guide user to publish when ready.
- Published stories: guide user to share.

## AI / External Service Notes

No new AI generation is part of Stage 2.

Stage 2 may prepare UI entry points for a future Project Story Builder, but those entry points should not promise unavailable functionality.

No new GitHub integration work is required. Existing GitHub-derived signals may remain where already present.

## Implementation Plan

1. Audit current dashboard and public profile UI hierarchy against the MVP loop.
2. Define story completeness helper logic using existing `project_story` fields.
3. Add dashboard next-action guidance.
4. Reframe dashboard copy and CTAs around proof-of-work and project stories.
5. Demote blog/network/digest surfaces where they compete with project-story work.
6. Update public profile project section language and card hierarchy around project stories.
7. Add or update focused controller/helper/system tests.
8. Update this brief with final decisions and verification results.

## Acceptance Criteria

- Dashboard primary messaging clearly points users toward project stories/proof-of-work.
- Dashboard shows a concrete next action based on the user's project/story state.
- Story completeness guidance uses a lightweight checklist/count, not a score.
- Blog, follows, network, and digest surfaces are visually secondary to project-story work.
- Public profile project section presents project stories as proof-of-work.
- Existing project/profile routes and public URLs continue to work.
- No new AI generation, resume builder, social network, discovery directory, or GitHub Insights rebuild is introduced.
- No public story completeness scoring or owner-only checklist UI appears on public profiles.
- No database migration is introduced unless implementation discovers a clear need.
- Tests cover the key dashboard/profile states touched by the change.

## Dashboard State Test Matrix

Stage 2 should cover these dashboard states:

1. User with no projects.
2. User with projects but no meaningful story content.
3. User with draft/unpublished project with meaningful story content.
4. User with published project but weak story content.
5. User with one published project story.
6. User with multiple published project stories.

## Verification Plan

Targeted checks:

```bash
bin/rails test test/controllers/dashboard_controller_test.rb
bin/rails test test/controllers/public_profiles_controller_test.rb
bin/rails test test/system/unclaimed_profile_ui_test.rb
```

Additional checks if project card/profile rendering changes broadly:

```bash
bin/rails test test/controllers/public_projects_controller_test.rb
bin/rails test test/integration/projects_management_test.rb
```

Baseline checks before handoff:

```bash
bin/rails db:migrate:status
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman
git status --short
```

## Rollout / Revert Plan

Rollout should be UI-only or helper-only where possible.

Preferred rollout:

- Preserve existing routes and data.
- Keep secondary sections accessible but lower priority.
- Do not remove user content.
- Avoid database migrations unless implementation discovers a clear need.

Revert plan:

- Revert dashboard/profile view changes.
- Remove any helper methods added solely for Stage 2 if unused.
- Existing project story data remains untouched.

## Open Questions

- [x] What should the top dashboard CTA be for users with no projects?
  Decision: "Create your first project story."
- [x] What should the top dashboard CTA be for users with projects but no story context?
  Decision: "Add story context."
- [x] What should the top dashboard CTA be for users with a published story?
  Decision: "Share your project story." If the published story has weak story content, prefer "Improve this story."
- [x] Should story completeness appear on public profiles?
  Decision: No. Keep completeness guidance private to the owner dashboard/project edit flow.
- [x] Should blog stats remain on the dashboard in Stage 2?
  Decision: Yes, but demoted below project-story guidance. Blog stats should not appear in the top dashboard hero or primary next-action panel during MVP.
- [x] Should follows/network/digest remain on the dashboard in Stage 2?
  Decision: Yes, but visually secondary. These surfaces should not use primary CTAs or compete visually with the project-story action panel.

## Decision Log

- 2026-05-29: Stage 2 should reframe dashboard/profile hierarchy around proof-of-work without rebuilding the whole product.
- 2026-05-29: Story completeness should be lightweight guidance, not a score.
- 2026-05-29: AI Story Builder and resume bullet generation are deferred to later MVP stages.
- 2026-05-29: Meaningful story content means at least two of six core story sections are present.
- 2026-05-29: Story completeness guidance is owner-facing only and should not appear on public profiles.
- 2026-05-29: Blog/network/digest dashboard surfaces remain available but visually secondary during Stage 2.
- 2026-05-29: Dashboard next-action branching is implemented in `Dashboard::ProofOfWorkNextAction`.
- 2026-05-29: Project-level story completeness helpers are implemented in `ProjectStory`.
- 2026-05-29: Public profile project cards use story overview as summary with description fallback.
- 2026-05-29: Targeted Stage 2 tests pass; RuboCop passes on app files and new presenter test.

## Progress

- [x] Audit dashboard/profile hierarchy.
- [x] Define story completeness helper approach.
- [x] Define next-action dashboard states.
- [x] Update dashboard copy and CTAs.
- [x] Demote secondary surfaces.
- [x] Update public profile project-story presentation.
- [x] Add/update targeted tests.
- [x] Update this brief with final decisions.

## Implementation Notes

- Added `Dashboard::ProofOfWorkNextAction` presenter for the six dashboard states.
- Added project story completion helpers to `ProjectStory`.
- Added a dashboard proof-of-work guidance panel.
- Reframed dashboard project language around project stories.
- Kept blog, network, digest, and social-card features present but visually secondary.
- Updated public profile project section language to "Project Stories."
- Kept public cards concise and free of owner-only completion guidance.

## Verification Results

Passed:

```bash
bin/rails test test/models/project_test.rb test/presenters/dashboard/proof_of_work_next_action_test.rb test/controllers/dashboard_controller_test.rb test/controllers/public_profiles_controller_test.rb
bin/rails test test/controllers/public_projects_controller_test.rb test/integration/projects_management_test.rb
bin/rails test test/models/project_test.rb test/presenters/dashboard/proof_of_work_next_action_test.rb test/controllers/dashboard_controller_test.rb test/controllers/public_profiles_controller_test.rb test/controllers/public_projects_controller_test.rb test/integration/projects_management_test.rb
RUBOCOP_CACHE_ROOT=tmp/rubocop_cache bin/rubocop app/models/concerns/project_story.rb app/presenters/dashboard/proof_of_work_next_action.rb app/controllers/dashboard_controller.rb test/presenters/dashboard/proof_of_work_next_action_test.rb
bin/rails db:migrate:status
```

Notes:

- `test/integration/projects_management_test.rb` currently reports existing skipped tests.
- Running RuboCop across existing touched controller/model test files also reports pre-existing array-spacing offenses outside the Stage 2 app code path.
