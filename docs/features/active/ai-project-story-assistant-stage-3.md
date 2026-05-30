# Feature Brief: AI Project Story Assistant Stage 3

**Status:** Draft  
**Owner:** Gustavo  
**Created:** 2026-05-29  
**Updated:** 2026-05-29  
**Related Strategy:** `docs/product/strategy-2026.md`  
**Related MVP Goal:** `docs/product/mvp-product-goal.md`  
**Depends On:** `docs/features/completed/project-stories-stage-1.md`, `docs/features/active/dashboard-profile-reframe-stage-2.md`

## Summary

Add an owner-facing AI assistant that helps developers improve or generate a structured project story from real project inputs.

The user-facing feature should be named **Project Story Builder**. It should help a developer turn rough project context into clearer proof-of-work content for the existing `project_story` fields.

This stage should focus only on project story generation/improvement. It should not generate resume bullets, social posts, recruiter summaries, or broad AI writing outputs.

Stage 3 should leave the user with a stronger editable project story, not a published asset that bypasses review.

## Product Intent

The MVP stays focused on the smallest complete proof-of-work loop:

```text
One developer creates or selects one real project, turns it into one structured public story, generates one practical reusable asset, and shares one public link.
```

Stage 3 advances the loop by helping users who have real work but rough storytelling. The assistant should make it easier to explain:

- What the project is
- What problem it solves
- What the developer personally did
- What was technically difficult
- What the developer learned
- What the project demonstrates

AI should clarify and structure real work. It must not invent accomplishments.

## Goals

- Add an owner-facing Project Story Builder entry point for projects.
- Generate or improve `project_story` fields from real project inputs.
- Preserve user review/edit control before generated content is saved.
- Ground output in existing project metadata, current story fields, and existing GitHub-derived signals when available.
- Keep generated content scoped to project story sections only.
- Avoid overwriting user-authored content without explicit confirmation.
- Reuse existing AI architecture where practical without forcing a large rewrite.

## Non-Goals

- Do not generate resume bullets in Stage 3.
- Do not generate LinkedIn posts, X/Twitter posts, recruiter summaries, or broad promotional assets.
- Do not create a full resume builder.
- Do not create a generic AI writing app.
- Do not create a public visitor chatbot.
- Do not replace Project Insight visitor Q&A.
- Do not rebuild GitHub Insights.
- Do not create broad discovery, featured stories, directories, marketplace, job board, or social-network features.
- Do not require every story field before saving or publishing.

## Users and Permissions

- Only project owners can generate or apply AI story suggestions for their own projects.
- Admin/super-admin behavior should remain explicit and follow existing authorization patterns if they can manage projects.
- Public visitors should never see story generation UI, prompts, drafts, or owner-only guidance.
- Existing project ownership, Pundit authorization, account status checks, and rate limits should be preserved.

## Current Behavior

Stage 1 added structured project stories:

- `projects.project_story` JSONB field
- `ProjectStory` concern
- public story overview fallback to `description`
- public story sections
- project form story fields
- public project story rendering

Stage 2 added dashboard/profile guidance:

- project story completeness helpers
- dashboard next-action presenter
- proof-of-work dashboard guidance
- public profile project story language

Existing AI architecture includes:

- `ArchitectService`
- `ArchitectSession`
- `ContextBuilder`
- `PromptStrategy`
- `ResultParser`
- `ModePolicy`
- mode-specific context builders, prompt strategies, and result parsers
- Project Insight Q&A for public project questions
- GitHub Insights snapshots and summaries

Current gap:

- There is no owner-facing Project Story Builder that generates or improves `project_story` content.
- The dashboard can point users toward weak/missing story context, but there is not yet an AI-supported flow to help them create that content.

## Proposed Behavior

### Entry Points

Project owners should be able to start Project Story Builder from project owner surfaces:

- Project edit/manage page
- Dashboard next-action panel when a project needs story context
- Possibly project index/card owner controls if already natural

Entry points should be owner-only and should not appear on public profiles or public project pages for visitors.

Recommended Stage 3 default:

- Add the first entry point on the project edit/manage surface.
- Let dashboard guidance link to that project owner surface when it already has a deterministic target project.
- Avoid introducing a separate global AI destination unless the implementation discovers a clear need.

### Builder Flow

The MVP flow should be practical and short:

1. User chooses a project.
2. DevvMe shows current project metadata/story context.
3. User may add rough notes or missing context.
4. AI generates suggested project story content.
5. User reviews the suggested fields.
6. User applies selected suggestions or copies them into the project story form.
7. Existing project story fields are saved only after user confirmation.

The assistant may be single-turn in Stage 3. A full multi-turn chat is optional only if it reuses existing architecture cleanly and does not delay the MVP loop.

Recommended Stage 3 default:

- Start with a single-turn generate/review/apply flow.
- Return missing-context questions as part of the generated response instead of starting with a long interview.
- Treat a multi-turn chat as a later enhancement if single-turn quality is not good enough.

### Story Fields To Generate

The assistant should focus on public project story fields:

- `overview`
- `problem`
- `intended_users`
- `why_built`
- `role`
- `technical_decisions`
- `hardest_challenge`
- `lessons_learned`
- `demonstrates`

Do not generate `promotion_notes` as a core Stage 3 output. It exists from Stage 1 but should remain optional/supporting.

### Review Before Apply

Generated content should never overwrite user-authored content automatically.

Preferred behavior:

- Show generated suggestions grouped by field.
- Make it clear which existing fields already have content.
- Allow users to apply all suggestions, apply selected fields, or discard.
- Preserve existing content unless the user confirms replacement.

## Apply Behavior

Generated suggestions should be field-level and reviewable.

For each generated field, the UI should show:

- Existing content, if present
- Suggested content
- Action: keep existing
- Action: replace with suggestion
- Action: apply only if blank

Default behavior should be conservative:

- Blank existing fields may be preselected for apply.
- Non-blank existing fields should not be preselected for replacement.
- Applying all suggestions should not replace non-blank fields unless the user explicitly chooses that option.

## Data Model / Contracts

Prefer no new database migration unless implementation discovers a clear need.

The primary saved output remains:

- `projects.project_story`

Generated suggestions should remain transient in Stage 3. Do not create a new database table for AI drafts or suggestions. The only durable save should happen when the user explicitly applies selected suggestions to `projects.project_story`.

Recommended generated suggestion payload:

```json
{
  "version": 1,
  "fields": {
    "overview": "",
    "problem": "",
    "intended_users": "",
    "why_built": "",
    "role": "",
    "technical_decisions": "",
    "hardest_challenge": "",
    "lessons_learned": "",
    "demonstrates": ""
  },
  "evidence_notes": [
    {
      "source": "project_metadata",
      "summary": ""
    }
  ],
  "missing_context_questions": []
}
```

Contract rules:

- Output must be structured enough to map safely into `project_story`.
- The AI response should be requested as strict JSON matching the suggestion contract.
- The parser should defensively handle invalid JSON, unknown keys, blank values, and malformed output.
- Unknown fields should be ignored.
- Invalid responses should produce a friendly owner-facing error and should not save anything.
- Blank generated fields should not overwrite existing fields.
- Generated suggestions should only target known `project_story` fields in Stage 3.
- Generated suggestions should not update project title, description, technologies, URLs, status, images, or GitHub-derived fields.
- Evidence notes are for review/debugging and should not be treated as public proof unless explicitly rendered later.
- Missing context questions should help the user add more detail without blocking save.

## UX Notes

The Project Story Builder should feel like a focused assistant, not a generic chat product.

Preferred UX:

- Keep it project-scoped.
- Show the project title and current story completeness.
- Ask for rough notes only when helpful.
- Generate a reviewable draft.
- Make apply/discard decisions obvious.
- Keep the user in control.

Avoid:

- Long onboarding copy
- Generic "ask AI anything" UI
- Public completion scores
- Auto-publishing generated story content
- Claims that AI knows impact, outcomes, users, or skills not present in inputs

Empty/weak story states:

- If the project has only title/description, use those plus optional rough notes.
- If the project has GitHub evidence, treat it as supporting signal.
- If context is sparse, AI should ask for missing details or generate conservative content.

## AI / External Service Notes

AI generation is part of Stage 3, but only for project story content.

Grounding inputs may include:

- Project title
- `description`
- technologies
- source/demo URLs
- existing `project_story` fields
- existing GitHub Insights summary when available
- existing Project Insight analysis when available
- owner-provided rough notes

AI must:

- Preserve the developer's voice and intent.
- Avoid exaggeration and unsupported claims.
- Avoid inventing metrics, users, employers, credentials, or impact.
- Distinguish GitHub-derived observations from user-provided claims.
- Ask for missing context when needed.
- Return structured output.
- Leave final save/apply control to the user.

Provider/model choice:

- Prefer reusing the existing app AI configuration initially.
- Keep token and output size bounded.
- Handle missing API keys with a friendly owner-facing message.

## Architecture Direction

Use existing architecture where it fits, but avoid forcing Stage 3 into a career-chat shape if a smaller project-scoped service is cleaner.

Recommended implementation direction:

- Add a project-scoped service such as `ProjectStory::GenerationService` or `ProjectStoryBuilder::GenerationService`.
- Reuse prompt/result parsing patterns from `PromptStrategy` and `ResultParser` where useful.
- Keep Project Insight separate; it remains visitor/project Q&A.
- Prefer project-scoped member actions over a separate global AI route.
- Keep the builder tied to a specific project.
- Let exact route names follow existing Rails app conventions after inspecting the current `ProjectsController` and routes.
- If using `ArchitectSession`, add a dedicated `project_story_builder` mode only if the session/conversation model is truly needed.
- If single-turn generation is enough, prefer a smaller service over a new chat/session workflow.

Default architecture decision for implementation planning:

- Start with a single-turn project-scoped generation service unless implementation needs conversation history.
- Keep the service small and explicit: gather context, call the configured AI provider, parse structured output, and return reviewable suggestions.
- Do not expand `ArchitectSession` unless there is a strong reason to persist project-story conversations.

Rate-limit direction:

- Stage 3 should include a simple owner-facing rate limit or guardrail if the app already has a rate-limit pattern.
- If no existing pattern exists, add a lightweight defensive check and document follow-up work rather than building a complex quota/billing system.

## Implementation Plan

1. Inspect existing project edit/manage flow and owner routes for the smallest Project Story Builder entry point.
2. Confirm the single-turn project-scoped service approach still fits the current code.
3. Define the structured generation response contract.
4. Add the generation service and result parser for project story suggestions.
5. Add owner-only controller action(s) for generating suggestions.
6. Add review/apply UI for generated field suggestions.
7. Ensure generated content never overwrites existing story fields without confirmation.
8. Add rate limits and friendly missing-key/failure states.
9. Add targeted tests for service, controller, authorization, parsing, and review/apply behavior.
10. Update this brief with final decisions and verification results.

## Acceptance Criteria

- A project owner can request AI story suggestions for one of their projects.
- The generated output maps to known `project_story` fields.
- Existing user-authored story fields are not overwritten without explicit confirmation.
- The user can review generated suggestions before saving.
- Sparse input produces conservative output or missing-context questions, not invented claims.
- Existing GitHub-derived signals are used only when already available.
- Public visitors cannot access generation UI or drafts.
- Project Insight remains separate from Project Story Builder.
- No resume bullet, social post, recruiter summary, broad writing, discovery, or directory feature is introduced.
- Tests cover generation contracts, owner access, and non-overwrite behavior.

## Verification Plan

Targeted checks:

```bash
bin/rails test test/services/project_story_builder/generation_service_test.rb
bin/rails test test/controllers/projects_controller_test.rb
bin/rails test test/controllers/public_profiles_controller_test.rb
bin/rails test test/models/project_test.rb
```

Additional checks if reusing ArchitectSession:

```bash
bin/rails test test/services/context_builder_test.rb
bin/rails test test/services/prompt_strategy_test.rb
bin/rails test test/services/result_parser_test.rb
bin/rails test test/controllers/architect/sessions_controller_test.rb
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
- No auto-save of generated content.
- No migration unless a durable draft/suggestion store is explicitly needed.
- Feature can be hidden by removing the entry point if needed.

Revert plan:

- Remove/hide Project Story Builder entry points.
- Remove controller action/service if not used.
- Existing `projects.project_story` data remains untouched.

## Open Questions

- [x] Should Stage 3 use a single-turn project-scoped generation service or a new `ArchitectSession` mode?
  Decision: start with a single-turn project-scoped generation service. Revisit `ArchitectSession` only if Stage 3 needs durable conversation history.
- [x] Should generated suggestions be saved as drafts before apply?
  Decision: no. Generated suggestions should remain transient in Stage 3. The only durable save should happen when the user explicitly applies selected suggestions to `projects.project_story`.
- [x] Should the builder ask guided questions before generating?
  Decision: use an optional rough-notes field first. Do not build a multi-step interview in Stage 3. Missing-context questions can be returned with the suggestion response and used to guide the user manually.
- [x] Which project page should host the entry point?
  Decision: add the first Project Story Builder entry point on the project edit/manage surface. Dashboard guidance may link to that surface when it has a deterministic target project.
- [x] Should GitHub evidence be shown in the review UI?
  Decision: show a small "signals considered" note only if existing GitHub-derived evidence is available and can be summarized safely. Do not build a major evidence viewer in Stage 3.

## Decision Log

- 2026-05-29: Stage 3 is scoped to AI project story generation/improvement only.
- 2026-05-29: User-facing feature name should be Project Story Builder.
- 2026-05-29: Resume bullets and promotion assets remain deferred to Stage 4.
- 2026-05-29: Generated story content must require user review/confirmation before saving.
- 2026-05-29: Generated suggestions remain transient; no AI draft/suggestion table in Stage 3.
- 2026-05-29: Stage 3 starts from project-scoped member actions rather than a global AI route.

## Progress

- [ ] Inspect project owner entry points.
- [ ] Decide service vs `ArchitectSession` mode.
- [ ] Define final structured response contract.
- [ ] Add generation service/result parsing.
- [ ] Add owner-only controller action(s).
- [ ] Add review/apply UI.
- [ ] Add rate limits/failure states.
- [ ] Add targeted tests.
- [ ] Update this brief with final decisions.
