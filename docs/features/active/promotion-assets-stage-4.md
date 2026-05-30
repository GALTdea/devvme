# Feature Brief: Promotion Assets Stage 4

**Status:** Implemented  
**Owner:** Gustavo  
**Created:** 2026-05-29  
**Updated:** 2026-05-30  
**Related Strategy:** `docs/product/strategy-2026.md`  
**Related MVP Goal:** `docs/product/mvp-product-goal.md`  
**Depends On:** `docs/features/completed/project-stories-stage-1.md`, `docs/features/active/dashboard-profile-reframe-stage-2.md`, `docs/features/active/ai-project-story-assistant-stage-3.md`

## Summary

Turn structured project stories into reusable career/promotion assets, starting with project-specific resume bullets.

Stage 4 should help a developer take one real project story and produce practical resume bullets they can reuse in a resume, job application, or professional profile. The first asset must be resume bullets. Other assets are useful later, but they should not delay the core MVP loop.

This stage should not build a full resume manager, generic AI writing tool, or social post generator.

## Product Intent

The MVP stays focused on the smallest complete proof-of-work loop:

```text
One developer creates or selects one real project, turns it into one structured public story, generates one practical reusable asset, and shares one public link.
```

Stage 4 completes the first reusable-asset part of that loop.

The user should feel:

```text
I can now explain this project in language that works outside DevvMe.
```

## Goals

- Generate project-specific resume bullets from an existing project story.
- Ground generated bullets in `project_story`, project metadata, and existing GitHub-derived signals when available.
- Keep the user in control with review/edit/copy behavior.
- Avoid overwriting user-authored project story content.
- Make resume bullets easy to copy and reuse outside DevvMe.
- Add a clear owner-facing entry point from project owner surfaces.
- Preserve the project story as the source of truth.

## Non-Goals

- Do not build a full resume builder.
- Do not manage full resume documents, sections, templates, PDFs, or job-application workflows.
- Do not generate LinkedIn posts, X/Twitter posts, recruiter summaries, cover letters, or broad promotional copy in Stage 4.
- Do not generate job-specific tailored bullets, ask for job descriptions, or build job-specific tailoring in Stage 4.
- Do not create a generic AI writing app.
- Do not create public visitor generation UI.
- Do not replace Project Story Builder.
- Do not replace Project Insight visitor Q&A.
- Do not rebuild GitHub Insights.
- Do not require published projects if implementation can safely support draft owner-only generation.
- Do not introduce discovery, featured stories, directories, marketplace, job board, or social-network features.

## Users and Permissions

- Only project owners can generate, view, or copy resume bullets for their own projects. Saving selected bullets is optional later and should not be required for the first implementation.
- Admin/super-admin behavior should follow existing project authorization patterns if they can manage projects.
- Public visitors should not see generation UI, owner-only asset drafts, or private controls.
- Generated resume bullets are owner-facing by default.
- Existing ownership, Pundit authorization, account status checks, and rate limits should be preserved.

## Current Behavior

Stage 1 added structured project stories:

- `projects.project_story` JSONB field
- project story form fields
- public story rendering
- description fallback behavior

Stage 2 added dashboard/profile guidance:

- proof-of-work dashboard guidance
- story completeness helpers
- public profile project story emphasis

Stage 3 added Project Story Builder:

- owner-facing AI story suggestions
- single-turn project-scoped generation
- review/apply behavior
- transient generated suggestions
- source-field protection for project story fields

Current gap:

- A developer can build and publish a project story, but cannot yet generate a reusable resume bullet asset from that story.

## Proposed Behavior

### Entry Points

Project owners should be able to generate resume bullets from project owner surfaces:

- Project edit/manage page
- Project Story Builder success/review area if it is natural
- Dashboard next-action panel when a project has a meaningful story and the next MVP step is asset generation

Entry points should be owner-only and project-scoped.

Recommended Stage 4 default:

- Add the first entry point on the project edit/manage surface near the story/proof-of-work tools.
- Keep the feature tied to a specific project.
- Prefer project-scoped member actions over a separate global AI route.

### Resume Bullet Flow

The MVP flow should be short:

1. User chooses a project.
2. DevvMe gathers the project story, metadata, technologies, and existing GitHub-derived signals when available.
3. AI generates a small set of project-specific resume bullets.
4. User reviews the bullets.
5. User can copy individual bullets, copy all bullets, or regenerate. Saving selected bullets is optional later if durable storage is introduced.

Resume bullets should be useful even if the project is not published, as long as the owner has enough story context. Public visitors should not see owner-only generation controls.

### Bullet Output

Default generated output:

- 3 to 5 project-specific resume bullets
- concise, action-oriented language
- grounded in real project details
- no fabricated metrics or unsupported impact
- no claims about employers, users, revenue, performance, or scale unless present in the story/evidence

Preferred bullet style:

- Start with a strong action verb.
- Name what was built or improved.
- Include relevant technologies only when they strengthen the bullet.
- Explain outcome or demonstrated skill without exaggeration.
- Keep bullets concise enough to paste into a resume with minimal editing.
- Each bullet should usually be one sentence and no more than two sentences.
- Avoid first-person language such as "I built..." in resume bullets.
- Prefer resume-style phrasing such as "Built...", "Designed...", "Implemented...", "Integrated...", "Improved...", or "Developed...".
- If no measurable outcome is provided, describe demonstrated work or capability instead of inventing impact.

Avoid:

- Generic filler like "worked on a project"
- Inflated business impact
- Unverified numbers
- Claims about production users unless provided
- Rewriting the whole resume

## Data Model / Contracts

Prefer no new database migration unless implementation discovers a clear need.

Source inputs may include:

- Project title
- `description`
- technologies
- source/demo URLs
- current `project_story` fields
- existing GitHub Insights summary when available
- existing Project Insight analysis when available
- owner-provided rough notes if the UI includes them

Recommended generated response contract:

```json
{
  "version": 1,
  "resume_bullets": [
    {
      "text": "",
      "focus": "technical_depth",
      "source_notes": []
    }
  ],
  "missing_context_questions": []
}
```

Contract rules:

- The AI response should be requested as strict JSON matching the response contract.
- The parser should defensively handle invalid JSON, unknown keys, blank values, and malformed output.
- Unknown keys should be ignored.
- Unknown focus values should be normalized to `general`.
- Invalid responses should produce a friendly owner-facing error and should not save anything.
- Blank bullets should be ignored.
- Generated bullets should not update project story fields, project metadata, GitHub-derived fields, profile fields, or resume files.
- Missing context questions should help the user improve the story without blocking copy/regeneration.

Allowed `focus` values:

- `technical_depth`
- `product_thinking`
- `problem_solving`
- `architecture`
- `user_impact`
- `collaboration`
- `learning_growth`
- `general`

Source notes:

- The review UI may show brief source notes such as "Based on project story," "Based on technologies," or "Based on GitHub signals" when available.
- Source notes should help trust but should not clutter the copy surface.

Read-only source rule:

- Resume bullet generation reads from `project_story`, project metadata, technologies, and available GitHub-derived signals.
- Resume bullet generation should never modify `project_story`, project metadata, profile fields, or GitHub-derived fields.

## Storage Decision

Decision:

- Stage 4 should start with transient, copy-only resume bullet suggestions.
- Do not persist generated bullets in the first implementation unless the implementation requires persistence for the review/copy UX.
- For Stage 4 MVP, copy-only generated bullets are acceptable.
- Saving selected bullets is optional and should not delay the first implementation.
- If persistence is later added, it should be project-scoped and owner-only, not a full resume model.
- Do not store bullets in public-facing story fields unless the UI explicitly separates owner-only assets from public story content.

## UX Notes

The asset generator should feel like a practical tool, not a new product area.

Preferred UX:

- Keep it project-scoped.
- Show the project title and story completeness context.
- Explain only enough to make the bullets easy to trust.
- Show bullets in a compact review/copy surface.
- Provide copy buttons for each bullet and all bullets.
- Show missing-context questions if the inputs are too thin.
- Keep public profile/project pages free of owner-only asset guidance.
- Stage 4 may include an optional "Anything specific you want these bullets to emphasize?" field.
- The emphasis field should be a simple textarea, not a job-description workflow or career questionnaire.
- Stage 4 bullets should be general project-specific bullets, not job-specific tailored bullets.
- Do not ask for job descriptions or build job-specific tailoring in this stage.

Avoid:

- Full-page resume-builder UI
- Long onboarding copy
- Multi-step career questionnaire
- Public asset scoring
- Auto-saving generated bullets into public story copy
- Asking for job descriptions in Stage 4

## AI / External Service Notes

AI generation is part of Stage 4, but only for project-specific resume bullets.

AI must:

- Ground bullets in user-provided story data, project metadata, and GitHub-derived signals when available.
- Ask for missing context when needed.
- Preserve the developer's intent.
- Avoid exaggeration and unsupported claims.
- Avoid inventing metrics, users, outcomes, employers, credentials, or impact.
- Keep output concise and reusable.
- Return structured output.
- Leave final review/copy/save control to the user.

Provider/model choice:

- Prefer reusing the existing app AI configuration initially.
- Keep token and output size bounded.
- Handle missing API keys with a friendly owner-facing message.

## Architecture Direction

Use the Stage 3 Project Story Builder architecture as the closest precedent.

Recommended implementation direction:

- Add a project-scoped service such as `ProjectPromotionAssets::ResumeBulletGenerationService` or `ProjectResumeBullets::GenerationService`.
- Reuse Stage 3 patterns for context gathering, strict JSON parsing, rate limits, owner-only member actions, and friendly failures.
- Keep the implementation independent from `ArchitectSession` unless there is a clear need for durable career-chat history.
- Keep Project Insight separate.
- Prefer project-scoped member actions over a separate global AI route.

Rate-limit direction:

- Reuse the Stage 3 rate-limit/guardrail pattern if available.
- Do not build a complex quota, billing, or credits system in Stage 4.

## Dashboard / Navigation Behavior

Stage 4 may update dashboard guidance only where it supports the MVP loop.

Recommended next-action behavior:

- If a user has a published or meaningful project story, dashboard guidance may point them toward generating resume bullets.
- Dashboard guidance should only prioritize resume bullet generation after the user has at least one meaningful project story.
- Resume bullet generation should not appear before create/improve/publish story actions.
- Do not demote create/improve/publish/share guidance if the user has not completed those earlier steps.
- Do not introduce a broad "AI assets" dashboard area in Stage 4.

## Acceptance Criteria

- A project owner can generate resume bullets for one of their projects.
- Generated bullets are grounded in the project story and known project context.
- Generated bullets are project-specific only.
- The user can review and copy generated bullets.
- Invalid AI responses do not save anything and show a friendly owner-facing error.
- Public visitors cannot access generation UI or owner-only generated assets.
- Project story content is not overwritten by resume bullet generation.
- No full resume builder, social post generator, recruiter summary, cover letter, discovery feature, or GitHub Insights rebuild is introduced.
- Tests or prompt assertions should cover that generated bullet instructions forbid invented metrics, employers, users, revenue, performance claims, or unsupported impact.
- Tests cover generation contracts, owner access, parsing failures, and public non-leakage.

## Verification Plan

Targeted checks:

```bash
bin/rails test test/services/project_resume_bullets/generation_service_test.rb
bin/rails test test/controllers/projects_controller_test.rb
bin/rails test test/controllers/dashboard_controller_test.rb
bin/rails test test/controllers/public_projects_controller_test.rb
bin/rails test test/models/project_test.rb
```

Additional checks if new presenter/helper logic is added:

```bash
bin/rails test test/presenters/dashboard/proof_of_work_next_action_test.rb
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

Preferred rollout:

- Owner-only entry point.
- No public visitor surface changes required.
- No auto-save into project story fields.
- No full resume builder.
- No migration unless durable project-level assets are explicitly needed.
- Feature can be hidden by removing the entry point if needed.

Revert plan:

- Remove/hide resume bullet entry points.
- Remove controller action/service if not used.
- Existing `projects.project_story` data remains untouched.

## Open Questions

- [x] Should Stage 4 bullets be transient copy-only suggestions or saved project-level assets?
  Decision: start transient/copy-only. Saving selected bullets is optional later and should not delay MVP.
- [x] Should resume bullets require a meaningful story threshold?
  Decision: no hard threshold. Allow generation with sparse context, but return conservative bullets and missing-context questions when story data is weak.
- [x] Should resume bullets be available for draft/unpublished projects?
  Decision: yes for owners, because resume reuse is private. Public visitors see nothing.
- [x] Should interview talking points be included in Stage 4?
  Decision: no. Defer until resume bullets work cleanly.

## Decision Log

- 2026-05-29: Stage 4 starts with project-specific resume bullets as the first required reusable asset.
- 2026-05-29: Full resume builder, social posts, recruiter summaries, and interview talking points are deferred.
- 2026-05-29: Generated bullets must be grounded in project story data and must not invent unsupported outcomes.
- 2026-05-30: Stage 4 starts with transient, copy-only resume bullet suggestions.
- 2026-05-30: Draft/unpublished owner projects may generate resume bullets when enough context exists.

## Progress

- [x] Inspect existing Stage 3 generation/apply architecture.
- [x] Decide transient vs persisted bullet behavior — transient, copy-only via session.
- [x] Define final structured response contract — `resume_bullets[]` with `text`, `focus`, `source_notes`.
- [x] Add resume bullet generation service/result parser — `ProjectResumeBullets::GenerationService`, `ResultParser`, `RateLimiter`.
- [x] Add owner-only project-scoped controller action(s) — `POST generate_resume_bullets`.
- [x] Add review/copy UI — `_resume_bullets`, `_resume_bullets_review`, Stimulus copy controller.
- [x] Add rate limits/failure states — 10/day, 30s cooldown per project.
- [x] Add targeted tests — service, controller, presenter, public non-leakage.
- [x] Update this brief with final decisions and verification results.

## Verification Results (2026-05-30)

```bash
bundle exec bin/rails test test/services/project_resume_bullets/
bundle exec bin/rails test test/controllers/projects_controller_test.rb
bundle exec bin/rails test test/presenters/dashboard/proof_of_work_next_action_test.rb
bundle exec bin/rails test test/controllers/public_projects_controller_test.rb
# 105 runs, 356 assertions, 0 failures
```
