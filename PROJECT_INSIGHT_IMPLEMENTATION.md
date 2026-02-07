# Project Insight - Source of Truth (v1)

**Feature:** Project Insight is an AI-powered feature on Devv.me that lets visitors ask intelligent questions about a developer's project and receive clear, recruiter-friendly explanations grounded in the project's real GitHub repository.

**Status:** Planning Finalized (Pre-Implementation)

**Document Purpose:** This file is the canonical implementation reference for Project Insight v1 decisions, scope, architecture, and rollout.

---

## Product Intent

Project Insight turns a static project page into an interactive technical conversation.

It is designed to:

- Explain what the project does and how it is built.
- Translate repository signals into recruiter-friendly language.
- Ground every answer in real repository evidence.
- Stay honest about uncertainty and tradeoffs.

Primary audience:

- Recruiters
- Hiring managers
- Non-technical collaborators

---

## Locked v1 Decisions

1. **Access model**
   - Only authenticated users can ask questions.
   - Rationale: protect usage/cost and reduce abuse.

2. **Repository support**
   - v1 supports public GitHub repositories only.
   - Private repository support is deferred to later versions.

3. **Canonical source URL**
   - `projects.source_code_url` is the canonical repository URL.
   - Legacy `projects.github_url` is fallback read-only compatibility.
   - Long-term direction: deprecate `github_url`.

4. **Model/provider for v1**
   - OpenAI only (reuse current app setup).

5. **Conversation format**
   - Single-turn Q&A per request (no persistent multi-turn thread in v1).

6. **Owner controls**
   - Project owner can toggle Project Insight on/off per project.
   - Manual editing/suppressing specific generated insights is out of scope for v1.

7. **Evidence policy**
   - Responses should include lightweight evidence references (files, dependencies, activity signals).

8. **Moderation scope**
   - Keep v1 moderation minimal: auth checks, rate limiting, input limits, basic guardrails.

---

## v1 Scope

In scope:

- Project-level opt-in for Project Insight.
- GitHub repo analysis pipeline (public repos).
- Authenticated ask endpoint.
- Recruiter-friendly grounded response generation.
- Evidence snippets/references in responses.
- Usage controls (quotas/cooldowns).
- Basic observability and tests.

Out of scope (post-v1):

- Private repo ingestion and token management.
- Multi-turn persistent visitor conversation history.
- Rich moderation workflows.
- Human editing of generated insights.
- Multi-provider model routing.

---

## Data and Domain Changes (Planned)

### `projects` table additions

- `project_insight_enabled:boolean` (`default: false`, `null: false`)
- `project_insight_last_analyzed_at:datetime`
- `project_insight_analysis:jsonb` (`default: {}`)

### Model behavior updates (`Project`)

- Add helper to resolve canonical GitHub repo URL:
  - prefer `source_code_url` when it is a GitHub URL
  - fallback to `github_url` for legacy records
- Validation when `project_insight_enabled=true`:
  - project must have a valid resolvable GitHub repository URL

---

## Architecture Plan

### 1) Analysis layer

Service (planned): `ProjectInsight::AnalysisService`

Responsibilities:

- Parse owner/repo from canonical project repo URL.
- Fetch relevant repository data (public GitHub API).
- Produce normalized analysis snapshot stored on the project.

Analysis snapshot should include:

- repository metadata summary
- architecture and structure signals
- dependency summary (manifest-based)
- maintenance/activity signals (commit cadence windows)
- strengths and tradeoffs
- evidence references used for generated responses

### 2) Answer layer

Service (planned): `ProjectInsight::AnswerService`

Responsibilities:

- Accept `(project, question, user)`.
- Build prompt from stored analysis snapshot.
- Generate concise recruiter-friendly grounded answer.
- Return response payload with answer + evidence references + caveats.

Guardrails:

- strict input length
- strict output token cap
- reject unsupported/unanswerable prompts with clear fallback

### 3) Controller/API layer

Authenticated endpoint (planned), e.g.:

- `POST /projects/:id/project_insight/ask`

Checks:

- `authenticate_user!`
- project visibility/access
- Project Insight enabled for project
- rate limits and cooldowns

### 4) UI layer

Public project page integration (`app/views/public_projects/show.html.erb`):

- Show Project Insight section only when enabled.
- Logged-out users see sign-in requirement messaging.
- Logged-in users see question input + answer card + evidence list + disclaimer.

---

## Repository/Data Inputs (v1)

Target inputs for analysis:

- Repo metadata (name, description, language, stars, forks, timestamps)
- Language mix
- Dependency manifests when available
- Representative code file samples (bounded)
- Recent commit activity summary
- Optional README signals

Design requirement:

- Every high-level statement in answers should map to at least one captured evidence signal.

---

## Operational Guardrails (v1 defaults)

Initial defaults (can be tuned after launch):

1. Max question length: `400` characters
2. Max answer output: `~400` tokens
3. Per-user daily asks: `20`
4. Per-user-per-project cooldown: `15` seconds

These are cost and abuse protections, not final policy guarantees.

---

## Security and Privacy Notes

v1 posture:

- Auth-required asking
- Public repository data only
- No private repository token ingestion in v1
- No storage of full repository mirrors
- Store compact analysis snapshots and evidence references only

Future private-repo phase will require:

- encrypted token handling
- least-privilege GitHub scopes
- explicit consent and revocation UX
- stronger auditability

---

## Rollout Plan

1. Implement behind feature flag.
2. Enable for internal/test projects first.
3. Validate:
   - answer quality
   - groundedness/evidence coverage
   - latency
   - cost per ask
4. Expand gradually after quality/cost checks pass.

---

## Test Strategy (v1)

Required test coverage areas:

- Model tests for new project validations/helpers
- Service tests for analysis generation and answer shaping
- Request/controller tests for auth, opt-in checks, limits, success path
- Integration test for ask flow on public project page

Also validate failure paths:

- missing/invalid repo URL
- empty analysis snapshot
- upstream API failure
- rate limit exceeded

---

## Open Questions (Deferred)

These are explicitly deferred beyond v1 unless reprioritized:

- Private repository support design and token lifecycle
- Multi-turn conversation memory per visitor/project
- Owner-driven answer editing/suppression
- Multi-model/provider abstraction
- Advanced moderation and safety filtering

---

## Implementation Order (Planned)

1. Migrations + `Project` model changes
2. Project settings form/controller updates
3. Analysis service + storage format
4. Ask service + response contract
5. Authenticated ask endpoint + rate limits
6. Public project page UI integration
7. Background analysis refresh job
8. Tests + instrumentation + staged rollout

