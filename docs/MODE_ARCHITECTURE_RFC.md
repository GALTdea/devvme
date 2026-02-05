# Career Architect Multi-Mode RFC

**Status:** Draft  
**Date:** 2026-02-04  
**Owner:** Gustavo  
**Scope:** Evolve Career Architect from single-use profile builder into a multi-mode platform.

---

## 1. Why This Change

Current implementation is optimized for one flow (Socratic profile building).  
As new use cases are added (Fit Gap, Mock Interview, Outreach), we need:

- A stable session model that knows which mode is running
- A clean context pipeline per mode
- Structured outputs per mode (instead of only free text)

This keeps features additive and avoids a large `if/else` code path.

---

## 2. Goals

- Add explicit session `mode` support with safe defaults.
- Add `target_data` input for mode-specific targets (JD, LinkedIn text, company notes).
- Introduce mode-specific context builders, prompt strategies, and result parsers.
- Preserve backward compatibility for existing `ArchitectSession` records.

## 3. Non-Goals

- No full RAG/vector DB in this phase.
- No UI redesign in this RFC.
- No removal of existing profile-builder flow.

---

## 4. Proposed Data Model

Use existing table `architect_sessions` (no rename required).

### 4.1 `architect_sessions` (new fields)

- `mode :string, null: false, default: "profile_builder"`
- `target_type :string, null: true`
- `target_data :jsonb, null: false, default: {}`
- `result_data :jsonb, null: false, default: {}`
- `context_version :integer, null: false, default: 1`

### 4.2 `architect_messages` (optional extension)

- Keep existing structure.
- Optional future add: `message_type :string` (`question`, `answer`, `system_note`, `artifact_hint`).

### 4.3 Optional new table for structured outputs

`architect_artifacts`

- `architect_session_id :bigint, null: false, fk`
- `artifact_type :string, null: false`  
  Examples: `fit_gap_analysis`, `resume_bullets`, `mock_interview_feedback`
- `title :string, null: true`
- `payload :jsonb, null: false, default: {}`
- `version :integer, null: false, default: 1`
- `created_at/updated_at`

Indexes:

- `index_architect_artifacts_on_architect_session_id`
- `index_architect_artifacts_on_artifact_type`

### 4.4 GitHub snapshot cache (Phase C)

`github_profile_snapshots`

- `user_id :bigint, null: false, unique`
- `username :string, null: false`
- `payload :jsonb, null: false, default: {}`
- `fetched_at :datetime`
- `created_at/updated_at`

Purpose: store a stable GitHub profile snapshot per user to avoid refetching for every analysis and to provide a consistent baseline for skills extraction.

---

## 5. Exact Domain Enums / Contracts

### 5.1 `ArchitectSession.mode`

Allowed values:

- `profile_builder`
- `fit_gap`
- `mock_interview`
- `outreach`

### 5.2 `ArchitectSession.target_type`

Allowed values:

- `job_description`
- `linkedin_profile`
- `company_profile`
- `none` (optional convention; otherwise `nil`)

### 5.3 `target_data` JSON shape (examples)

Fit Gap:

```json
{
  "job_description_text": "...",
  "job_title": "Senior Backend Engineer",
  "company_name": "Acme"
}
```

Mock Interview:

```json
{
  "interview_type": "technical",
  "role_title": "Rails Engineer",
  "focus_areas": ["system design", "testing"]
}
```

### 5.4 GitHub snapshot payload shape (summary)

Top-level keys (current shape used by context builders):

```json
{
  "profile": {
    "login": "johndoe",
    "name": "John Doe",
    "bio": "Backend engineer...",
    "company": "Acme",
    "location": "Austin, TX",
    "blog": "https://johndoe.dev",
    "public_repos": 12,
    "html_url": "https://github.com/johndoe",
    "followers": 42,
    "following": 10
  },
  "repos": [
    {
      "name": "api-service",
      "description": "Rails API",
      "language": "Ruby",
      "stargazers_count": 8,
      "forks_count": 2,
      "topics": ["ruby-on-rails", "api"],
      "updated_at": "2026-02-01T10:20:30Z",
      "pushed_at": "2026-02-01T10:15:00Z",
      "archived": false,
      "fork": false,
      "html_url": "https://github.com/johndoe/api-service"
    }
  ],
  "readmes": {
    "api-service": "README text (truncated)"
  },
  "skills_profile": {
    "languages": ["Ruby", "TypeScript"],
    "topics": ["Ruby On Rails", "Api", "Backend"],
    "readme_signals": ["Ruby on Rails", "PostgreSQL", "Docker"],
    "combined": ["Ruby", "TypeScript", "Ruby On Rails", "PostgreSQL", "Docker", "Api", "Backend"]
  }
}
```

Notes:
- `skills_profile.combined` is the canonical list used for skills merging and Fit Gap context.
- Topic normalization is title-cased and deduped.

---

## 6. Service/Class Architecture

Keep `ArchitectService` as orchestration entrypoint, but delegate mode logic.

### 6.1 New classes

- `ContextBuilder`
- `ContextBuilders::ProfileBuilder`
- `ContextBuilders::FitGap`
- `ContextBuilders::MockInterview`
- `ContextBuilders::Outreach`

- `PromptStrategy`
- `PromptStrategies::ProfileBuilder`
- `PromptStrategies::FitGap`
- `PromptStrategies::MockInterview`
- `PromptStrategies::Outreach`

- `ResultParser`
- `ResultParsers::ProfileBuilder`
- `ResultParsers::FitGap`
- `ResultParsers::MockInterview`
- `ResultParsers::Outreach`

- `ModePolicy` (validates mode-target compatibility and required inputs)

### 6.2 Suggested method contracts

```ruby
ContextBuilder.build(user:, mode:, target_data: {})
PromptStrategy.for(mode).qa_system_prompt(session:, context:)
PromptStrategy.for(mode).finalize_system_prompt(session:, context:)
ResultParser.for(mode).parse_finalize(text:, session:)
ModePolicy.validate!(mode:, target_type:, target_data:)
```

---

## 7. Controller/API Contract Evolution

Current `Architect::SessionsController#create` accepts `goal`, `pasted_content`.  
Extend to accept:

- `mode`
- `target_type`
- `target_data`

Behavior:

- If not provided, default to existing flow:
  - `mode = profile_builder`
  - `target_type = nil`
  - `target_data = {}`

---

## 8. Phased Migration Plan

## Phase A: Schema + Backward Compatibility

1. Migration 1: add `mode`, `target_type`, `target_data`, `result_data`, `context_version` to `architect_sessions`.
2. Backfill existing rows with:
   - `mode = "profile_builder"`
   - `target_data = {}`
   - `result_data = {}`
   - `context_version = 1`
3. Add model validations + enum-like inclusion checks.
4. Keep existing UI/controller behavior unchanged.

## Phase B: Mode Scaffolding (No New UI Yet)

1. Add `ContextBuilder`, `PromptStrategy`, `ResultParser`, `ModePolicy`.
2. Route existing profile flow through `profile_builder` strategy.
3. Ensure no behavior regressions via existing tests.

## Phase C: Fit Gap Mode (First New Mode)

1. Add mode-specific context builder using profile + projects + `target_data` JD.
2. Add parser that writes structured `result_data`:
   - `requirements`
   - `evidence`
   - `gaps`
3. Add unified JD analysis page on top of `result_data`.

## Phase D: Artifacts + Resume/Gap Guidance

1. Add `architect_artifacts` table.
2. Persist evidence cards, resume bullets, and recommendations as artifacts.
3. Add export and iteration workflows.

---

## 9. Testing Strategy

- Unit tests:
  - `ModePolicy` input validation
  - each `ContextBuilders::*` output shape
  - each `ResultParsers::*` parser correctness
- Service tests:
  - `ArchitectService` delegates by mode
  - backward compatibility defaults
- Request/integration tests:
  - `profile_builder` still works with old params
  - `fit_gap` session creation + result persistence

---

## 10. Rollout & Safety

- Keep behind existing Career Architect beta gate.
- Add per-mode metrics:
  - session start rate
  - completion rate
  - average tokens/cost
  - error rate
- Add per-mode rate limits if costs rise unexpectedly.

---

## 11. Open Decisions

- Do we store `goal` for all modes, or make `goal` profile-only long-term?
- Should `target_data` be encrypted at rest for sensitive pasted content?
- Do we require `architect_artifacts` in Phase C, or defer until Phase D?

---

## 12. Recommended Next Action

Implement **Phase A** first (schema + validation + compatibility), then immediately scaffold **Phase B** before adding Fit Gap UI.  
This is the safest path to scale features without rewrites.

---

## 13. Phase A Implementation Checklist (Concrete)

Use this exact order to keep rollout safe.

### 13.1 Create migration

Recommended file:

- `db/migrate/20260204120000_add_multi_mode_fields_to_architect_sessions.rb`

Suggested migration body:

```ruby
class AddMultiModeFieldsToArchitectSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :architect_sessions, :mode, :string, null: false, default: "profile_builder"
    add_column :architect_sessions, :target_type, :string
    add_column :architect_sessions, :target_data, :jsonb, null: false, default: {}
    add_column :architect_sessions, :result_data, :jsonb, null: false, default: {}
    add_column :architect_sessions, :context_version, :integer, null: false, default: 1

    add_index :architect_sessions, :mode
    add_index :architect_sessions, :target_type
  end
end
```

### 13.2 Update model constants and validations

File:

- `app/models/architect_session.rb`

Add constants:

```ruby
MODES = %w[profile_builder fit_gap mock_interview outreach].freeze
TARGET_TYPES = %w[job_description linkedin_profile company_profile].freeze
```

Add validations:

```ruby
validates :mode, inclusion: { in: MODES }
validates :target_type, inclusion: { in: TARGET_TYPES }, allow_nil: true
```

Add helper predicates (recommended):

```ruby
def mode_profile_builder? = mode == "profile_builder"
def mode_fit_gap? = mode == "fit_gap"
def mode_mock_interview? = mode == "mock_interview"
def mode_outreach? = mode == "outreach"
```

### 13.3 Keep controller backward compatible

File:

- `app/controllers/architect/sessions_controller.rb`

Permit new params while defaulting to existing behavior:

```ruby
permitted = params.fetch(:architect_session, {}).permit(:goal, :pasted_content, :mode, :target_type, target_data: {})
mode = permitted[:mode].presence || "profile_builder"
target_type = permitted[:target_type].presence
target_data = permitted[:target_data].is_a?(Hash) ? permitted[:target_data] : {}
```

Pass through to service start call (or session creation path) without changing current UX.

### 13.4 Add service compatibility

File:

- `app/services/architect_service.rb`

Update `start_session` signature (backward compatible):

```ruby
def start_session(user, goal, pasted_content: nil, mode: "profile_builder", target_type: nil, target_data: {})
```

Persist new fields on session create:

```ruby
ArchitectSession.create!(
  user: user,
  goal: goal.to_s,
  mode: mode,
  target_type: target_type,
  target_data: target_data || {},
  status: :in_progress,
  context_snapshot: context
)
```

### 13.5 Add tests before shipping

Recommended test files:

- `test/models/architect_session_test.rb`
- `test/controllers/architect/sessions_controller_test.rb`
- `test/services/architect_service_test.rb`

Minimum assertions:

- default mode is `profile_builder`
- invalid mode is rejected
- `target_data` defaults to `{}`
- existing create flow (without mode params) still succeeds
- create flow with mode/target_data persists correctly

### 13.6 Deployment safety checklist

1. Deploy migration first.
2. Deploy app code with defaults and permissive parsing.
3. Smoke test current profile-builder flow.
4. Verify no old sessions fail loading.
5. Enable new modes only behind a feature flag (or admin-only trigger) until Phase B is complete.

### 13.7 Definition of Done for Phase A

- Migration applied in all environments.
- Existing profile-builder behavior unchanged.
- New fields present and persisted.
- Model and request tests cover old + new paths.
- No increase in `ArchitectReplyJob` failure rate after deploy.
