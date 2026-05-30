# Stage Brief Decision Checklist

Use this checklist before creating or refining a DevvMe feature stage brief.

The goal is to make each brief implementation-ready without accidentally expanding the MVP into adjacent products.

## Default Stage Doctrine

For DevvMe MVP stages, prefer:

```text
Project-scoped
Owner-only
Review-first
Transient by default
Strict contracts for AI
Public surfaces stay polished
No new tables until behavior demands it
```

## 0. Smallest Successful Outcome

Default recommendation:

Each stage should define the smallest user-visible outcome that moves the MVP loop forward.

Brief should answer:

- What can the user do after this stage that they could not do before?
- Which exact MVP loop step does this stage advance?
- What is the simplest complete path through the feature?
- What output counts as success?

Template:

```text
This stage is successful when a user can ______.
```

## 1. Storage Decision

Default recommendation:

- Keep AI-generated output transient first.
- Use existing durable source fields when the user explicitly applies or saves content.
- Use `projects.project_story` as the durable source of truth for project story content.
- Add a new table only when the product behavior clearly needs persistence, history, querying, or reuse across sessions.

Brief should answer:

- Is this output transient, copy-only, session-backed, JSONB-backed, or persisted in a model/table?
- If persisted, who owns it and where is it displayed?
- Does persistence need migration now, or can it wait?

## 2. Apply / Save Behavior

Default recommendation:

- AI output should be review-before-save.
- No auto-overwrite.
- No auto-publish.
- For project story fields, use field-level apply with conservative defaults.
- For reusable assets, start copy-only unless persistence is clearly needed.

Brief should answer:

- Can generated output modify durable data?
- Does the user apply all, apply selected fields, copy only, or discard?
- What happens to blank existing fields?
- What happens to non-blank existing fields?
- What confirmation is required before replacement?

## 3. Source Of Truth

Default recommendation:

- Project data and `projects.project_story` are the main MVP source of truth.
- AI may read project metadata, technologies, story fields, and existing GitHub-derived signals.
- AI should only write to fields explicitly named by the stage.

Brief should answer:

- Which models and fields can this feature read from?
- Which models and fields can this feature write to?
- Which fields are explicitly read-only?
- Which public/private boundaries must be preserved?

## 4. Mutation Boundaries

Default recommendation:

Each stage should explicitly define what data it is allowed to change and what data it must never change.

AI features should only mutate durable data after user confirmation, and only the fields explicitly named by the stage.

Brief should answer:

- Can this stage update `project_story`?
- Can it update project metadata?
- Can it update public profile fields?
- Can it update GitHub-derived fields?
- Can it update publish status?
- Can it create new records?
- Can it delete anything?

Template:

```text
Allowed mutations:
-

Forbidden mutations:
-
```

## 5. Explicit Non-Goals

Default recommendation:

Every stage should name adjacent features that are tempting but deferred.

Common DevvMe non-goals:

- Full resume builder
- Resume documents, templates, PDFs, or job-application workflows
- Social post generator
- Recruiter summaries
- Cover letters
- Job-specific tailoring
- Generic AI writing
- Public visitor chatbot
- Project Insight replacement
- GitHub Insights rebuild
- Discovery directories
- Featured stories
- Marketplace, job board, or social-network features

Brief should answer:

- What is intentionally not being built?
- Which adjacent AI outputs are deferred?
- Which existing features must remain secondary?

## 6. Route / Surface Preference

Default recommendation:

- Prefer project-scoped owner surfaces.
- Use project edit/manage as the first surface for owner-only project tools.
- Let dashboard guidance link to the project surface when it has a deterministic target.
- Avoid global AI routes unless the product behavior truly spans projects.
- Public pages should not show owner controls.

Brief should answer:

- Where does the user start this flow?
- Is this a project member action, dashboard action, profile action, or public route?
- Is the route owner-only?
- Should the dashboard point to it now or later?

## 7. Parsing / Output Contract

Default recommendation for AI features:

- Request strict JSON.
- Define the exact response shape.
- Define allowed enum values.
- Ignore unknown keys.
- Normalize unknown enum values to a safe default such as `general`.
- Ignore blank values where appropriate.
- Show friendly errors for invalid responses.
- Never save anything after malformed or invalid AI output.

Brief should answer:

- What JSON shape should AI return?
- Which keys are allowed?
- Which enum values are allowed?
- What happens to unknown keys?
- What happens to malformed JSON?
- What happens if AI returns valid JSON with unsafe or unsupported claims?
- What content safety rules should the prompt and tests enforce?
- What tests or prompt assertions should protect the contract?

## 8. Dashboard Sequencing

Default recommendation:

Dashboard actions should follow the MVP loop:

```text
Create/select project
Add story context
Improve with AI
Publish story
Generate resume bullets
Share public link/profile
```

Brief should answer:

- When should this action appear?
- What user/project state must exist first?
- Which earlier actions should outrank this one?
- What deterministic project should the CTA target?
- Should this stage update dashboard guidance at all?

## 9. Public vs Owner-Only Behavior

Default recommendation:

- Public visitors see polished proof-of-work only.
- Owner-only guidance stays on dashboard/project management surfaces.
- Public pages should not leak drafts, AI prompts, generated suggestions, completion checklists, private notes, or internal evidence/debug details.

Brief should answer:

- What does the project owner see?
- What does a public visitor see?
- What must never appear publicly?
- Are generated outputs public, private, or owner-copy-only?

## 10. Testing Expectations

Default recommendation:

Each stage should include behavior-focused tests, not brittle long-copy assertions.

Common test areas:

- Authorization and ownership
- Public non-leakage
- Model/helper behavior
- Presenter/controller behavior
- Parser behavior for AI features
- Invalid AI output handling
- No overwrite without confirmation
- No mutation of forbidden fields
- Dashboard state sequencing

For AI prompt features, tests or prompt assertions should cover that generated instructions forbid:

- Invented metrics
- Invented employers
- Invented users
- Invented revenue
- Unsupported performance claims
- Unsupported impact

Brief should answer:

- Which existing tests need updates?
- Which new tests should be added?
- Which failure cases matter most?
- Which public/owner boundary should be tested?

## 11. Rollout / Revert

Default recommendation:

Prefer additive, owner-only, reversible changes.

Brief should answer:

- Can this feature be hidden by removing entry points?
- Does it add a database migration?
- Does it mutate existing records?
- Does it touch public pages?
- What remains if reverted?

Template:

```text
Rollout:
-

Revert:
-
```

## 12. Open Questions Policy

Default recommendation:

- Prefer decisions with rationale over open-ended questions.
- Leave a question open only when implementation discovery is genuinely needed.
- If the likely path is clear, write it as a decision or recommendation.

Brief should answer:

- Which decisions are already made?
- Which questions truly require implementation discovery?
- Which recommendations should become default build instructions?

## Brief Creation Prompt

Before drafting a new stage brief, answer these quickly:

1. What is the smallest user-visible outcome?
2. What is the durable source of truth?
3. What can this stage read?
4. What can this stage write?
5. What stays transient or copy-only?
6. What is owner-only?
7. What must never show publicly?
8. What adjacent products are explicitly out of scope?
9. What is the preferred route/surface?
10. What tests prove the stage stayed inside its boundaries?
