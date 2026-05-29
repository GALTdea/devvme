# Feature Brief: Project Stories Stage 1

**Status:** Draft  
**Owner:** Gustavo  
**Created:** 2026-05-29  
**Updated:** 2026-05-29  
**Related Strategy:** `docs/product/strategy-2026.md`  

## Summary

Reposition the existing DevvMe project experience around structured project stories. This stage turns the current project CRUD/public project surface into the foundation for proof-of-work: a developer can explain what they built, why it matters, what was hard, what they learned, and what the work demonstrates.

This stage should reuse the existing `Project` model and public project flow where practical. It should not rebuild the app or introduce a large new AI workflow yet.

## Product Intent

DevvMe's new north star is:

```text
Does this help a developer turn real work into public proof?
```

Projects are the most important content type for that direction. Today, projects mostly behave like portfolio entries. Stage 1 should begin moving them toward proof-of-work stories that are clearer, more structured, more shareable, and easier to build on with AI later.

## Goals

- Establish "project story" as the core content shape for public proof-of-work.
- Improve the project creation/editing experience with guided story prompts.
- Improve public project pages so they read like structured proof-of-work, not just portfolio cards.
- Preserve existing project CRUD, publishing, draft/archive states, ordering, GitHub/demo links, and image support.
- Prepare a clean foundation for later AI-assisted story generation and promotion assets.

## Non-Goals

- Do not rebuild DevvMe from scratch.
- Do not replace the existing `Project` model unless the storage decision requires it and is explicitly approved.
- Do not implement the full AI story-generation workflow in this stage.
- Do not redesign the entire dashboard, homepage, Explore, blog, follows, or email digest systems.
- Do not remove existing project data or break existing public project/profile URLs.

## Users and Permissions

- Project owners can create, edit, publish, draft, archive, reorder, and delete their own project stories.
- Public visitors can view published project stories through existing public profile/project surfaces.
- Admin and super-admin behavior should remain explicit and authorized through existing admin patterns.
- Existing Pundit authorization and user ownership boundaries must be preserved.

## Current Behavior

Current project behavior is centered on portfolio-style project entries:

- Users can create and manage projects.
- Projects include title, description, technologies, status, display order, source/demo URLs, images, and thumbnails.
- Public profiles display published projects.
- GitHub Insights and Project Insight already provide repository-derived context for some projects.

Relevant existing areas likely include:

- `app/models/project.rb`
- `app/controllers/projects_controller.rb`
- `app/controllers/public_projects_controller.rb`
- `app/views/projects/`
- `app/views/public_projects/`
- `app/views/public_profiles/`
- `test/models/project_test.rb`
- `test/controllers/projects_controller_test.rb`
- `test/controllers/public_projects_controller_test.rb`
- `test/integration/github_insights_public_page_test.rb`

## Proposed Behavior

Project entries should begin behaving as project stories.

A v1 project story should help explain:

- Project overview
- Problem solved
- Intended users
- Why it was built
- Developer's role
- Tech stack
- Key technical decisions
- Hardest challenge
- What the developer learned
- What the project demonstrates
- GitHub, live demo, screenshots, and supporting links

The project edit flow should guide developers to provide story-quality context without making the form feel heavy or corporate.

The public project page should present the story in a readable proof-of-work format, with existing GitHub/demo/images preserved.

## Data Model / Contracts

Stage 1 should use an additive versioned JSONB field on `projects`.

Decision:

- Add a `project_story` jsonb field to `projects`.
- Store story data with an explicit `version`.
- Do not require any story sections in Stage 1.
- Keep the existing `description` field separate.
- Use `description` as a public fallback when story overview content is blank.

Initial v1 story contract:

```json
{
  "version": 1,
  "overview": "",
  "problem": "",
  "intended_users": "",
  "why_built": "",
  "role": "",
  "technical_decisions": "",
  "hardest_challenge": "",
  "lessons_learned": "",
  "demonstrates": "",
  "promotion_notes": ""
}
```

Decision rationale:

- Easy to render on public pages
- Easy to edit in Rails forms
- Easy to validate enough without over-constraining early product learning
- Easy for future AI flows to generate and revise
- Safe to migrate existing projects without data loss
- Avoids premature schema rigidity while the story shape is still being validated

## UX Notes

The project form should feel guided, not bureaucratic.

Preferred direction:

- Keep basic project metadata familiar and quick.
- Add story prompts as clear sections.
- Make story fields optional at first if needed for migration safety.
- Provide helpful labels and short prompt text.
- Preserve draft/published workflows.
- Avoid requiring users to complete every story field before saving.

Public project story pages should:

- Lead with what the project is and why it matters.
- Surface the developer's role and proof-of-work sections clearly.
- Preserve screenshots, GitHub link, live demo, and technologies.
- Keep GitHub-derived evidence visually distinct from user-written story content.
- Use a lighter structured rendering update in Stage 1, not a full dedicated page redesign.
- Leave Project Insight naming unchanged in Stage 1.

## AI / External Service Notes

AI generation is not part of Stage 1 implementation unless explicitly added later.

Stage 1 should prepare for future AI by:

- Defining story sections clearly.
- Keeping fields structured enough for prompts.
- Distinguishing user-provided claims from GitHub-derived signals.
- Avoiding generated content that invents accomplishments.

GitHub Insights and Project Insight should be treated as existing evidence systems that may later feed story generation or public evidence sections.

## Implementation Plan

1. Add a versioned `project_story` jsonb field to `projects`.
2. Add or update the project story data contract.
3. Update project create/edit forms with guided story fields.
4. Update strong params, validations, model helpers, and tests.
5. Update public project story rendering.
6. Ensure existing projects still render correctly with partial or empty story data.
7. Add or update targeted tests.
8. Update docs with final storage and rendering decisions.

## Acceptance Criteria

- Existing projects continue to work without data loss.
- A project owner can add story-oriented content to a project.
- A project owner can save draft/published projects with partial story content.
- Public project pages render story sections when present.
- Empty story sections do not create awkward blank public UI.
- Existing GitHub/demo/image/technology fields still work.
- Authorization and ownership boundaries remain intact.
- Tests cover the new story fields/rendering behavior.

## Verification Plan

Targeted checks:

```bash
bin/rails test test/models/project_test.rb
bin/rails test test/controllers/projects_controller_test.rb
bin/rails test test/controllers/public_projects_controller_test.rb
bin/rails test test/integration/github_insights_public_page_test.rb
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

Rollout should be migration-safe and backwards compatible.

Preferred rollout:

- Add story fields without requiring them for existing projects.
- Render new sections only when content exists.
- Keep existing project description as a fallback.
- Avoid changing public URLs.

Revert plan depends on storage decision:

- If jsonb/columns are additive, hide UI and stop rendering new fields.
- If separate model is used, preserve records but remove entry points.
- Do not remove migrated story data until the direction is confirmed.

## Open Questions

- [x] Should "project story" be stored as structured columns, JSON, Action Text, a separate model, or a hybrid?
  Decision: use a versioned JSONB field on `projects` for Stage 1.
- [x] Which story sections are required for v1, if any?
  Decision: none are required in Stage 1.
- [x] Should the existing `description` field map to `overview`, remain separate, or become a fallback?
  Decision: keep `description` separate and use it as fallback.
- [x] Should public project pages get a dedicated redesign in this stage, or a lighter rendering update?
  Decision: do a lighter structured rendering update in Stage 1.
- [x] Should GitHub-derived evidence be included on the same page in Stage 1 or reserved for Stage 2?
  Decision: keep it on the same page if it already exists, but visually separate it from user-written story content.
- [x] Should "Project Insight" naming be changed now, later, or left as-is?
  Decision: leave it as-is for Stage 1.

## Decision Log

- 2026-05-29: Stage 1 starts with project stories because project proof-of-work is the new core content type.
- 2026-05-29: Existing project capabilities should be preserved and redirected rather than replaced.
- 2026-05-29: Full AI story generation is deferred until project story structure is established.
- 2026-05-29: Project story data will use a versioned JSONB field on `projects` in Stage 1.
- 2026-05-29: No story sections are required in Stage 1.
- 2026-05-29: Existing `description` remains separate and acts as public fallback when story overview is blank.
- 2026-05-29: Public project pages get a lighter structured rendering update, not a full redesign.
- 2026-05-29: Existing GitHub-derived evidence stays on the same page when present, visually separated from user-written story content.
- 2026-05-29: Project Insight naming remains unchanged for Stage 1.

## Progress

- [x] Resolve storage approach.
- [x] Define final v1 story section contract.
- [ ] Update project forms.
- [ ] Update project persistence and params.
- [ ] Update public project story display.
- [ ] Add/update tests.
- [ ] Update docs with final decisions.
