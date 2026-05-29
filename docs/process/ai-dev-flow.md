# AI Development Flow

DevvMe uses an artifact-driven, staged AI development flow. The goal is to let AI move quickly while keeping product intent, architecture, verification, and decisions durable inside the repository.

## Core Principle

AI tools are collaborators, not project memory. Durable context belongs in docs, feature briefs, tests, commits, and code.

Every meaningful product decision should also be checked against the DevvMe north star:

```text
Does this help a developer turn real work into public proof?
```

## Stage 1: Orient

Before implementation, gather the relevant context:

- Read `docs/AGENTS.md`.
- Read `docs/features/_constraints.md`.
- Read `docs/product/strategy-2026.md` for product-direction work.
- Read the relevant feature brief.
- Read nearby code and tests.
- Read relevant architecture docs or root-level historical implementation docs.

Output of this stage:

- A clear understanding of the goal
- Known constraints
- Relevant files and tests
- Any open questions

## Stage 2: Define

For meaningful product or architecture work, create or update a feature brief before coding.

Use a full brief for:

- New product workflows
- AI features
- Data model changes
- Background jobs and external integrations
- Authorization or privacy-sensitive work
- Cross-cutting refactors

Use a light brief for:

- Small UI changes
- Copy changes
- Narrow bug fixes
- Config changes
- Small refactors

Implementation should not begin while the brief has unresolved questions that affect product behavior, data model, cost, security, or rollout.

## Stage 3: Slice

Break implementation into small, reviewable slices. Each slice should have:

- One intended behavior change
- A clear file scope
- A local verification command
- A natural commit boundary when possible

Avoid large mixed changes that combine product behavior, UI polish, refactoring, and test rewrites in one pass.

## Stage 4: Implement

During implementation:

- Follow Rails conventions and existing project patterns.
- Keep controllers thin.
- Use Pundit authorization for protected resources.
- Preserve user ownership and account-status constraints.
- Use services/jobs for external calls and longer-running work.
- Add or update tests near the behavior.
- Update the feature brief as decisions or scope change.

## Stage 5: Verify

Run targeted verification after each slice, then broader verification at stage boundaries.

Targeted examples:

```bash
bin/rails test test/models/project_test.rb
bin/rails test test/controllers/projects_controller_test.rb
bin/rails test test/services/github_insights/sync_service_test.rb
```

Baseline before merge or handoff:

```bash
bin/rails db:migrate:status
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman
git status --short
```

If verification cannot be completed, document the gap in the handoff.

## Stage 6: Handoff

Every completed task should leave a clear trail:

- What changed
- Why it changed
- Tests or checks run
- Known risks or follow-ups
- Docs updated, if product or architecture decisions changed

For larger features, update the brief status and move it from `docs/features/active/` to `docs/features/completed/` when complete.

## Suggested Tool Roles

Cursor:

- Fast local pair programming
- Focused implementation slices
- View/component edits
- Nearby tests and refactors

Codex:

- Repo-wide reading and reasoning
- Coordinated multi-file changes
- Test/lint verification
- Code review and cleanup
- Documentation consolidation

ChatGPT/GPT:

- Feature definition
- Product framing
- Acceptance criteria
- Prompt design
- Tradeoff analysis

Claude:

- Long-form architecture review
- Product narrative review
- Brief critique
- Risk review

Gemini:

- Second-opinion review
- Research/context cross-checks
- Alternative strategy exploration

No tool owns the truth. All durable decisions should land in repository docs.
