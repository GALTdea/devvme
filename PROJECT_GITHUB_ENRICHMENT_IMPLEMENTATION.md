# Project GitHub Enrichment - Source of Truth (v1)

**Feature:** Automatically collect high-signal GitHub repository data for each project so project pages show recruiter- and PM-relevant evidence about quality, ownership, execution, and technical depth.

**Status:** Planning Finalized (Pre-Implementation)

**Document Purpose:** Canonical implementation reference for GitHub enrichment decisions, architecture, storage, sync behavior, and rollout for project pages.

---

## Product Intent

Project pages should go beyond static descriptions and expose real delivery signals from GitHub.

It is designed to:

- Generate a trustworthy "Project Overview" from repository evidence.
- Surface stack/architecture hints with confidence levels.
- Show activity and ownership signals that indicate maintenance health.
- Summarize issue/PR problem-solving patterns.
- Give non-engineers a fast quality read without requiring repo deep dives.

Primary audience:

- Recruiters
- Hiring managers
- Engineering managers
- Product/project managers

---

## Locked v1 Decisions

1. **Repository support**
   - v1 supports public GitHub repositories only.
   - Private repository ingestion is deferred.

2. **Canonical source URL**
   - `projects.source_code_url` is canonical.
   - `projects.github_url` remains legacy fallback read-only compatibility.

3. **Sync triggers**
   - Automatic lightweight sync when project is created/updated with a GitHub URL.
   - Manual deep sync via "Refresh GitHub Insights" button on project settings/page.

4. **Processing mode**
   - Ingestion is asynchronous using background jobs.
   - UI should never block on GitHub API calls.

5. **Snapshot strategy**
   - Store compact normalized snapshots + computed metrics.
   - Do not mirror full repositories in the app database.

6. **Scoring policy**
   - Display descriptive signals and ranges, not a single opaque "score."
   - Include caveats when signals are sparse.

7. **Rate/cost posture**
   - Cache API responses per sync run.
   - Backoff on API failures and expose sync status in UI.

---

## v1 Scope

In scope:

- GitHub metadata sync for projects with valid public repository URLs.
- Overview signals, stack/architecture signals, activity/ownership signals, issue/PR signals.
- Automatic sync on URL set/change.
- Manual deep sync action.
- Recruiter-friendly summary generation from normalized metrics.
- Sync status and last-updated metadata on project page/settings.
- Tests and instrumentation.

Out of scope (post-v1):

- Private repositories and GitHub OAuth scope management.
- Per-visitor conversational Q&A memory.
- Manual editing of each computed metric.
- Cross-repository benchmark comparisons.
- Multi-provider VCS support (GitLab/Bitbucket).

---

## Signal Taxonomy (v1)

### 1) Project Overview Signals

- Repo name, description, homepage, topics, license.
- Stars/forks/watchers/open issues.
- Default branch, created date, last push date.
- README quality hints (length, structure sections, setup instructions present).
- Release/tag presence.

### 2) Tech Stack & Architecture Signals

- Language breakdown percentages.
- Dependency manifests detected (`Gemfile`, `package.json`, `requirements.txt`, etc.).
- Framework/tooling fingerprints (Rails, React, Next.js, Docker, Terraform, CI configs).
- Monorepo indicators (workspace configs, multiple package roots).
- Test and quality tooling presence (RSpec/Minitest, linters, formatters, coverage tools).

### 3) Activity & Ownership Signals

- Commit cadence (30/90 day windows).
- Active contributors in recent windows.
- Bus-factor proxy (share of commits from top contributor).
- Maintainer continuity (gaps/inactivity windows).
- Recent release cadence signal.

### 4) Issues/PR Problem-Solving Signals

- Open vs closed issue ratio.
- Median issue close time (bounded sample).
- PR throughput and median merge time.
- Review participation signals (comment/review presence).
- Change size tendencies (small/medium/large PR distribution).

### 5) Recruiter/PM-Friendly Derived Signals

- Delivery consistency ("active maintenance", "sporadic", "inactive").
- Collaboration signal ("single-maintainer", "small team", "multi-contributor").
- Quality posture ("tests + CI detected", "limited quality tooling").
- Execution evidence highlights with references.

---

## Data and Domain Changes (Planned)

### `projects` table additions

- `github_insights_enabled:boolean` (`default: true`, `null: false`)
- `github_insights_sync_status:string` (`default: "never"`, values: `never`, `queued`, `syncing`, `ready`, `failed`)
- `github_insights_last_synced_at:datetime`
- `github_insights_last_error:text`
- `github_insights_summary:jsonb` (`default: {}`)

### New snapshots table

`project_github_insight_snapshots`:

- `project_id:references`
- `sync_type:string` (`light`, `deep`)
- `source:string` (`auto`, `manual`)
- `captured_at:datetime`
- `repo_payload:jsonb`
- `metrics_payload:jsonb`
- `highlights_payload:jsonb`
- `errors_payload:jsonb`
- `duration_ms:integer`

### Model behavior updates (`Project`)

- Canonical GitHub URL resolver:
  - prefer `source_code_url` if GitHub URL
  - fallback to legacy `github_url`
- Enqueue sync when canonical GitHub URL added/changed.
- Helper predicates for UI:
  - `github_insights_ready?`
  - `github_insights_failed?`
  - `github_insights_stale?`

---

## Architecture Plan

### 1) URL + repo identity layer

Service: `GithubInsights::RepoResolver`

Responsibilities:

- Parse owner/repo from canonical URL.
- Normalize URL variants (`https`, `www`, trailing `.git`).
- Reject unsupported/non-GitHub URLs.

### 2) Ingestion layer

Service: `GithubInsights::FetchService`

Responsibilities:

- Fetch public repo metadata and bounded activity data via GitHub API.
- Respect pagination bounds/time windows.
- Return normalized raw payload map for downstream metric generation.

### 3) Metrics/summary layer

Service: `GithubInsights::ComputeService`

Responsibilities:

- Transform raw payload into stable metrics schema.
- Build recruiter-friendly highlights + caveats.
- Compute confidence per major signal group.

### 4) Persistence/orchestration layer

Service: `GithubInsights::SyncService`

Responsibilities:

- Drive fetch -> compute -> persist flow.
- Update project sync status fields.
- Save immutable snapshot row per run.

### 5) Job layer

Job: `GithubInsightsSyncJob`

Responsibilities:

- Execute light/deep sync asynchronously.
- Retry transient API failures.
- Avoid duplicate concurrent syncs per project.

### 6) UI layer

Project settings/page updates:

- Show current sync status + timestamp.
- "Refresh GitHub Insights" button (manual deep sync).
- Recruiter-friendly insights cards when status is `ready`.
- Empty/failure states with actionable retry messaging.

---

## Sync Triggers and Behavior

1. **Auto light sync**
   - Trigger: create/update project where canonical GitHub URL is newly set or changed.
   - Goal: quick baseline metrics.

2. **Manual deep sync**
   - Trigger: user clicks refresh button.
   - Goal: richer issue/PR/review/activity metrics.

3. **Scheduled refresh (recommended)**
   - Trigger: periodic job (e.g., daily/weekly).
   - Goal: keep stale projects current.

4. **Concurrency and staleness rules**
   - Skip new sync if same project already `syncing`.
   - Mark stale if `last_synced_at` exceeds threshold (e.g., 7 days).

---

## API Inputs and Bounds (v1 defaults)

- Repo metadata + languages: always.
- Commits window: last 90 days (bounded page count).
- Pull requests: recent closed + open sample (bounded).
- Issues: recent closed + open sample (bounded, excluding PRs).
- Contributors: top contributors sample.

Boundaries:

1. Max files inspected for architecture fingerprints: `<= 200`
2. Max commits sampled: `<= 500`
3. Max PRs sampled: `<= 200`
4. Max issues sampled: `<= 200`

---

## Security, Privacy, and Reliability Notes

- Public repository data only in v1.
- No full source mirror persistence.
- Store only compact analysis payloads and evidence references.
- Log sync failures with sanitized error messages (no sensitive headers/tokens).
- Use retries with exponential backoff for transient API/network errors.
- Add basic circuit-break behavior when GitHub API is unavailable.

---

## Rollout Plan

1. Ship behind feature flag.
2. Enable for internal/test accounts first.
3. Validate:
   - sync success rate
   - median sync duration
   - insights usefulness/readability
   - API usage/rate-limit behavior
4. Expand to all users after thresholds are acceptable.

---

## Test Strategy (v1)

Required coverage:

- Model tests for URL resolver, sync state transitions, enqueue conditions.
- Service tests for fetch/compute/persist paths.
- Job tests for retry + concurrency protection.
- Controller/request tests for manual refresh auth/authorization.
- Integration tests for project page states (`queued`, `ready`, `failed`).

Failure-path tests:

- invalid or non-GitHub URL
- repository not found/renamed
- GitHub API timeout/rate-limit
- partial payloads (missing data buckets)
- recompute on stale snapshot

---

## Open Questions (Deferred)

- Private repository support and OAuth/GitHub App design.
- How much raw evidence should be visible vs collapsed in UI.
- Whether to keep multiple historical snapshots in UI timeline.
- Cross-project normalization (e.g., "above average response time").

---

## Phased Build Checklist

### Phase 0: Guardrails and Config

- [ ] **Step 0.1: Add feature flag and defaults**
  - Status: Not started
  - Files: `config/initializers/features.rb` (or existing feature flag config), `config/application.rb` (if needed)
  - Notes: Flag key for GitHub enrichment rollout (`github_project_enrichment`)

- [ ] **Step 0.2: Add GitHub API configuration**
  - Status: Not started
  - Files: `config/environment.example`, `README.md`, `config/credentials.yml.enc` (or ENV usage docs)
  - Notes: Token/env documentation, timeout defaults, retries

---

### Phase 1: Data Model and Project Hooks

- [x] **Step 1.1: Add project insight state columns**
  - Status: Done
  - Files: `db/migrate/*_add_github_insights_fields_to_projects.rb`, `db/schema.rb`
  - Dependencies: Phase 0
  - Columns:
    - `github_insights_enabled:boolean` (`default: true`, `null: false`)
    - `github_insights_sync_status:string` (`default: "never"`)
    - `github_insights_last_synced_at:datetime`
    - `github_insights_last_error:text`
    - `github_insights_summary:jsonb` (`default: {}`)

- [x] **Step 1.2: Add snapshots table**
  - Status: Done
  - Files: `db/migrate/*_create_project_github_insight_snapshots.rb`, `db/schema.rb`
  - Dependencies: Step 1.1
  - Table: `project_github_insight_snapshots`

- [x] **Step 1.3: Create snapshot model**
  - Status: Done
  - Files: `app/models/project_github_insight_snapshot.rb`
  - Dependencies: Step 1.2
  - Notes: `belongs_to :project`, enum/validation for `sync_type` and `source`

- [x] **Step 1.4: Update Project model**
  - Status: Done
  - Files: `app/models/project.rb`
  - Dependencies: Steps 1.1-1.3
  - Additions:
    - canonical GitHub URL resolver (`source_code_url` then `github_url`)
    - state helpers (`github_insights_ready?`, `github_insights_failed?`, `github_insights_stale?`)
    - enqueue callback when canonical GitHub URL changes

---

### Phase 2: Core Services

- [x] **Step 2.1: Implement URL resolver**
  - Status: Done
  - Files: `app/services/github_insights/repo_resolver.rb`
  - Dependencies: Phase 1
  - Notes: Parse and normalize `owner/repo`, reject unsupported URLs

- [x] **Step 2.2: Implement GitHub fetch service**
  - Status: Done
  - Files: `app/services/github_insights/fetch_service.rb`
  - Dependencies: Step 2.1
  - Notes: Collect bounded metadata/languages/commits/issues/PRs/contributors

- [x] **Step 2.3: Implement metrics compute service**
  - Status: Done
  - Files: `app/services/github_insights/compute_service.rb`
  - Dependencies: Step 2.2
  - Notes: Produce normalized metrics + highlights + caveats

- [x] **Step 2.4: Implement orchestration sync service**
  - Status: Done
  - Files: `app/services/github_insights/sync_service.rb`
  - Dependencies: Steps 2.1-2.3
  - Notes: Fetch -> compute -> persist snapshot + project summary/status updates

---

### Phase 3: Background Jobs and Reliability

- [x] **Step 3.1: Add sync job**
  - Status: Done
  - Files: `app/jobs/github_insights_sync_job.rb`
  - Dependencies: Step 2.4
  - Notes: Supports `light` and `deep` sync modes

- [x] **Step 3.2: Add dedupe/concurrency guards**
  - Status: Done
  - Files: `app/jobs/github_insights_sync_job.rb`, `app/services/github_insights/sync_service.rb`
  - Dependencies: Step 3.1
  - Notes: Skip when project currently syncing

- [x] **Step 3.3: Add retry/backoff and error mapping**
  - Status: Done
  - Files: `app/jobs/github_insights_sync_job.rb`, `app/services/github_insights/fetch_service.rb`
  - Dependencies: Steps 3.1-3.2
  - Notes: Handle timeout, not found, rate-limited responses cleanly

---

### Phase 4: Manual Refresh + Owner Controls

- [x] **Step 4.1: Add controller endpoint for manual refresh**
  - Status: Done
  - Files: `app/controllers/projects_controller.rb` (or project settings controller), `config/routes.rb`
  - Dependencies: Phase 3
  - Notes: Auth + ownership checks + enqueue deep sync

- [x] **Step 4.2: Add owner-facing refresh UI**
  - Status: Done
  - Files: `app/views/projects/*` (or settings views), relevant partials/components
  - Dependencies: Step 4.1
  - Notes: Show status badge, last sync timestamp, retry button

---

### Phase 5: Public Project Page Insights

- [x] **Step 5.1: Render recruiter-friendly insight cards**
  - Status: Done
  - Files: `app/views/public_projects/show.html.erb`, insight partials in `app/views/public_projects/`
  - Dependencies: Phase 4
  - Cards:
    - Project Overview
    - Tech Stack & Architecture
    - Activity & Ownership
    - Issues/PR Problem-Solving

- [x] **Step 5.2: Add ready/queued/failed/empty UI states**
  - Status: Done
  - Files: `app/views/public_projects/show.html.erb`, state partials/components
  - Dependencies: Step 5.1

- [x] **Step 5.3: Add evidence and caveat display**
  - Status: Done
  - Files: `app/views/public_projects/*`
  - Dependencies: Step 5.1
  - Notes: Keep references compact and non-technical where possible

---

### Phase 6: Scheduled Refresh

- [ ] **Step 6.1: Add stale-project refresher job**
  - Status: Not started
  - Files: `app/jobs/github_insights_stale_refresh_job.rb`
  - Dependencies: Phase 5
  - Notes: Queue light/deep sync based on staleness window

- [ ] **Step 6.2: Register recurring schedule**
  - Status: Not started
  - Files: scheduler config used by app (`config/recurring.yml`, `config/schedule.rb`, or existing scheduler setup)
  - Dependencies: Step 6.1

---

### Phase 7: Testing and Instrumentation

- [ ] **Step 7.1: Model tests**
  - Status: Not started
  - Files: `test/models/project_test.rb`, `test/models/project_github_insight_snapshot_test.rb`
  - Dependencies: Phases 1-3

- [ ] **Step 7.2: Service tests**
  - Status: Not started
  - Files: `test/services/github_insights/repo_resolver_test.rb`, `test/services/github_insights/fetch_service_test.rb`, `test/services/github_insights/compute_service_test.rb`, `test/services/github_insights/sync_service_test.rb`
  - Dependencies: Phase 2

- [ ] **Step 7.3: Job tests**
  - Status: Not started
  - Files: `test/jobs/github_insights_sync_job_test.rb`, `test/jobs/github_insights_stale_refresh_job_test.rb`
  - Dependencies: Phases 3 and 6

- [ ] **Step 7.4: Controller/request/integration tests**
  - Status: Not started
  - Files: `test/controllers/*_test.rb`, `test/integration/*github_insights*_test.rb`
  - Dependencies: Phases 4-5

- [ ] **Step 7.5: Instrumentation and rollout checks**
  - Status: Not started
  - Files: service/job files + logging/metrics initializer if present
  - Dependencies: Phases 3-6
  - Track:
    - sync success/failure rate
    - median sync duration
    - queued-to-ready latency
    - top failure reasons

---

### Phase 8: Launch Sequence

- [ ] **Step 8.1: Internal-only feature-flag rollout**
  - Status: Not started
  - Dependencies: Phase 7

- [ ] **Step 8.2: Validate quality and reliability thresholds**
  - Status: Not started
  - Dependencies: Step 8.1

- [ ] **Step 8.3: Gradual general rollout**
  - Status: Not started
  - Dependencies: Step 8.2
