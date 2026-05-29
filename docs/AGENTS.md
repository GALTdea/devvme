# DevvMe Agent Guide

This is the shared starting point for AI-assisted development in DevvMe. Use it before making code changes in Cursor, Codex, ChatGPT, Claude, Gemini, or any other AI tool.

## Project Snapshot

DevvMe is a Rails 8 developer portfolio platform. It helps developers publish professional profiles, projects, blog posts, GitHub-backed project evidence, and AI-assisted career/profile content.

Current major product areas:

- Public developer profiles and project portfolios
- Blog publishing and profile activity
- Admin/user management, invitation access, and featured profiles
- Career Architect AI profile-building flows
- Project GitHub enrichment and Project Insight features
- Visitor/profile analytics and email digests

## Stack

- Ruby 3.4.1
- Rails 8.0.2
- PostgreSQL
- Devise authentication
- Pundit authorization
- Hotwire: Turbo and Stimulus
- Tailwind CSS and Flowbite
- Solid Queue, Solid Cache, and Solid Cable
- FriendlyId, Noticed, Pagy, Action Text, Active Storage
- Minitest test suite under `test/`

## Read Before Coding

For any non-trivial change, read these first:

1. `docs/AGENTS.md`
2. `docs/process/ai-dev-flow.md`
3. `docs/features/_constraints.md`
4. `README.md`
5. The relevant feature brief under `docs/features/`
6. The relevant architecture or data docs:
   - `docs/DATA_MODEL.md`
   - `docs/MODE_ARCHITECTURE_RFC.md`
   - Root-level implementation docs until they are migrated

If there is no feature brief for meaningful product or architecture work, create one before implementation.

## Working Rules

- Start with context. Do not jump from vague product language straight to code.
- Keep changes small enough to review and verify.
- Prefer Rails conventions and existing local patterns.
- Keep controllers thin. Put business logic in models, services, jobs, or policies.
- Use Pundit for authorization and preserve tenant/user ownership boundaries.
- Use migrations for schema changes. Do not hand-edit `db/schema.rb`.
- Use Hotwire and Stimulus for Rails-native interactivity.
- Use Tailwind/Flowbite conventions already present in the app.
- Update durable docs when decisions change. Chat history is not project memory.
- Stop and ask when open questions affect product direction, security, data model, cost, or user privacy.

## Planning Modes

Use planning/consultation mode for:

- Strategic product direction
- New feature definition
- Data model or architecture changes
- AI prompt/provider decisions
- Security, privacy, cost, or rollout choices
- Any work with unresolved questions in the brief

Use implementation/agent mode for:

- Executing a clear feature brief
- Focused bug fixes
- Small UI and copy improvements
- Test additions
- Refactors with a defined target and verification path

## Feature Briefs

Feature briefs live under `docs/features/`.

- Use `_full-brief-template.md` for major features, architecture changes, AI features, data model work, or user-facing workflows.
- Use `_light-brief-template.md` for small UI, copy, config, cleanup, or narrow refactor tasks.
- Keep active work in `docs/features/active/`.
- Move completed work to `docs/features/completed/`.
- Move deferred ideas to `docs/features/parked/`.

Implementation should pause if a brief has unresolved questions that affect behavior or architecture.

## Verification

This project uses Minitest, not RSpec.

Baseline verification:

```bash
bin/rails db:migrate:status
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman
git status --short
```

For small slices, run targeted tests near the change first, then broaden before merge:

```bash
bin/rails test test/models/project_test.rb
bin/rails test test/controllers/projects_controller_test.rb
bin/rails test test/services/github_insights/sync_service_test.rb
```

When a full command cannot be run locally, record what was run, what was skipped, and why.

## Documentation Map

Canonical docs should live under `docs/`:

- `docs/AGENTS.md` - shared AI/developer operating guide
- `docs/process/ai-dev-flow.md` - staged AI development process
- `docs/process/verification.md` - verification command reference
- `docs/product/strategy-2026.md` - current strategic direction and open questions
- `docs/features/` - feature briefs and implementation artifacts
- `docs/architecture/` - architecture references and future migrated docs
- `docs/decisions/` - ADR-style durable decisions

Root-level implementation docs are historical and should be migrated gradually as related areas are touched.

