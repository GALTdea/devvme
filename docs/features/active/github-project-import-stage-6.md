# Feature Brief: GitHub Project Import Stage 6

**Status:** Draft  
**Owner:** Gustavo  
**Created:** 2026-06-03  
**Updated:** 2026-06-03  
**Related Strategy:** `docs/product/strategy-2026.md`  
**Related MVP Goal:** `docs/product/mvp-product-goal.md`  
**Depends On:** `docs/features/completed/project-stories-stage-1.md`, `docs/features/active/ai-project-story-assistant-stage-3.md`

## Summary

Add an owner-facing GitHub import flow to the new project page so a developer can select or paste a GitHub repository and prefill the project creation form with trustworthy repository-derived data.

The feature should help users move from "I have work on GitHub" to "I have a draft DevvMe project story I can review and publish" with less manual form entry.

The import should prefill clear metadata immediately and treat inferred story content as a reviewable draft. It should not silently publish, overwrite existing user-authored content, or present guesses as facts.

## Product Intent

The MVP loop starts with:

```text
Connect work -> Build project story -> Publish proof -> Generate resume bullets -> Share externally
```

GitHub Project Import strengthens the first step. Many target users already have real work in repositories but struggle to translate repository details into a public project story. This feature should reduce blank-page friction by turning existing GitHub evidence into editable project form content.

This supports the DevvMe north star:

```text
Does this help a developer turn real work into public proof?
```

The answer is yes if the import stays grounded in real repository data and keeps the developer in control of final wording.

## Goals

- Add a GitHub import entry point to the project creation flow.
- Support connected GitHub users selecting repositories from their account.
- Support a fallback paste-a-GitHub-URL path for public repositories.
- Prefill basic project fields from deterministic GitHub data.
- Draft story-adjacent fields only when the data supports them, and keep them editable before save.
- Reuse existing GitHub Insights services where practical.
- Preserve manual project creation for users without GitHub or with non-GitHub work.
- Make private repository access explicit and owner-controlled.

## Non-Goals

- Do not create a generic GitHub analytics dashboard.
- Do not clone, mirror, or store full repositories.
- Do not require GitHub to create a project.
- Do not automatically publish imported projects.
- Do not automatically overwrite saved projects in this stage.
- Do not support GitLab, Bitbucket, or other VCS providers in this stage.
- Do not infer personal claims such as motivation, role, lessons learned, or impact without review.
- Do not replace Project Story Builder, Project Insight, or GitHub Insights.

## Users and Permissions

- Only authenticated users can access the new project page and import GitHub repositories.
- A user can import only into their own unsaved project form.
- Connected GitHub users can list repositories available to their OAuth token.
- Private repositories require GitHub OAuth and should be clearly labeled as private in the picker.
- Public repository URL import can work without GitHub OAuth, subject to GitHub API rate limits and repository accessibility.
- Admin/super-admin behavior should not get special import powers unless explicitly added later.
- Public visitors should never see import controls, private repository metadata, drafts, or GitHub OAuth state.

## Current Behavior

The new project page at `app/views/projects/new.html.erb` renders the shared project form partial.

The form at `app/views/projects/_form.html.erb` currently lets users manually enter:

- `title`
- `description`
- `project_story` fields
- thumbnail and images
- `technologies_display`
- `live_url`
- `source_code_url`
- status, ordering, featured state, Project Insight, and GitHub enrichment settings

Existing GitHub-related behavior includes:

- Users can connect GitHub OAuth.
- OAuth currently requests `read:user,user:email,repo,read:org`.
- Projects can store a GitHub repository URL in `source_code_url`.
- `Project#project_github_repo_url` resolves GitHub repo URLs from `source_code_url` or legacy `github_url`.
- `GitHubInsights::RepoResolver` resolves canonical owner/repo coordinates.
- `GitHubInsights::FetchService` fetches repo metadata, languages, README, file tree, manifests, commits, PRs, issues, contributors, and releases.
- `GitHubInsights::ComputeService` turns raw GitHub payloads into summary metrics.
- Saved projects with GitHub enrichment enabled enqueue a background GitHub insights sync.

Current gap:

- A user cannot pick a repository while creating a project.
- A user cannot prefill the project creation form from GitHub before saving.
- GitHub enrichment currently happens after a project exists, so it does not reduce blank-form friction on creation.

## Proposed Behavior

### Entry Point

Add a compact GitHub import panel above the project form on `projects/new`.

The panel should support two paths:

1. **Connected picker:** for users with GitHub OAuth connected.
2. **Paste URL:** for public GitHub repository URLs, available to all authenticated users.

The user should still be able to ignore the panel and manually create a project.

### Connected Picker

When the current user has GitHub connected:

- Show an "Import from GitHub" action.
- Open or reveal a searchable repository picker.
- List repositories owned by the authenticated GitHub user.
- Do not include organization repositories in the first slice, even when the token can access them through `read:org`.
- Show enough metadata to choose confidently:
  - repo full name
  - private/public indicator
  - primary language
  - description
  - last pushed date when available
- Let the user choose one repo and apply a prefill draft to the form.

Recommended initial sorting:

- recently pushed repositories first
- hide forked repositories by default
- offer an "Include forks" filter if the picker can support it without adding significant complexity
- archived repositories lower or visually marked

Rationale:

- Owner repositories are the cleanest first-slice signal for "my project."
- Organization repositories can introduce team ownership, permission, and attribution ambiguity.
- Forks are often dependency/source snapshots, experiments, or contribution branches; they can still be valid proof-of-work, but should require explicit user intent.

### Paste URL Import

When the user pastes a GitHub URL:

- Validate that the URL points to `github.com/:owner/:repo`.
- Fetch public metadata with the app token or unauthenticated GitHub API fallback.
- If the repository is private or inaccessible, prompt the user to connect GitHub.
- Apply the same prefill draft shape as the connected picker.

### Prefill Behavior

Import should fill only empty fields by default.

For a new unsaved form this usually means all basic fields can be filled. If the user typed before importing, the UI should avoid surprise overwrites.

Recommended first-stage field mapping:

- `title`: humanized repo name or repo display name.
- `description`: repo description; README-derived summary only if repo description is blank.
- `source_code_url`: canonical `https://github.com/:owner/:repo`.
- `live_url`: repo homepage when present and valid.
- `technologies_display`: top languages plus selected topics and manifest-derived stack signals, capped by existing project validation.
- `project_story[overview]`: concise repo description or README summary.
- `project_story[technical_decisions]`: conservative notes from detected manifests, CI, Docker, test directories, monorepo shape, and framework hints.
- `project_story[demonstrates]`: conservative skills/proof statement from languages and tooling signals.
- `github_insights_enabled`: true when available.
- `project_insight_enabled`: true by default for imported GitHub repositories with a valid repository URL, while keeping the visible checkbox editable before create.

Fields that should remain user-authored unless AI review is added:

- `project_story[problem]`
- `project_story[intended_users]`
- `project_story[why_built]`
- `project_story[role]`
- `project_story[hardest_challenge]`
- `project_story[lessons_learned]`
- `project_story[promotion_notes]`

### Save Behavior

Applying an import should not save the project automatically.

The user should review the prefilled form, edit it, upload images if desired, choose draft/published status, and click "Create Project."

On create, the existing project save behavior and GitHub insights background sync should continue to run.

## Data Model / Contracts

No schema change is required for the first implementation slice.

Recommended internal service contract:

```ruby
GitHubProjectPrefillService.call(
  user: current_user,
  repository_url: "https://github.com/owner/repo"
)
```

Possible return shape:

```ruby
{
  "repository" => {
    "owner" => "owner",
    "name" => "repo",
    "full_name" => "owner/repo",
    "canonical_url" => "https://github.com/owner/repo",
    "private" => false,
    "homepage" => "https://example.com",
    "pushed_at" => "2026-06-01T12:00:00Z"
  },
  "project" => {
    "title" => "Repo",
    "description" => "Short repository description",
    "source_code_url" => "https://github.com/owner/repo",
    "live_url" => "https://example.com",
    "technologies_display" => "Ruby, Rails, PostgreSQL",
    "github_insights_enabled" => true
  },
  "project_story" => {
    "overview" => "Editable overview grounded in the repository.",
    "technical_decisions" => "Detected Rails app with PostgreSQL and CI workflow.",
    "demonstrates" => "Shows Ruby, Rails, testing, and deployment-oriented project work."
  },
  "evidence" => [
    {
      "field" => "technologies_display",
      "source" => "github_languages",
      "summary" => "Ruby and JavaScript detected by GitHub language stats."
    }
  ],
  "warnings" => []
}
```

Recommended repository list endpoint return shape:

```ruby
{
  "repositories" => [
    {
      "full_name" => "owner/repo",
      "url" => "https://github.com/owner/repo",
      "description" => "Repository description",
      "private" => false,
      "fork" => false,
      "archived" => false,
      "language" => "Ruby",
      "pushed_at" => "2026-06-01T12:00:00Z"
    }
  ]
}
```

Durable GitHub Insights snapshots should continue to be created by the existing post-save sync path rather than by the prefill endpoint unless a later implementation decision says otherwise.

## UX Notes

The import panel should feel like a helper, not a required step.

Recommended states:

- Not connected: show paste URL and a clear GitHub connect action for private repo support.
- Connected: show picker and paste URL.
- Loading repos: show a spinner or disabled import controls.
- Search empty: show no matching repositories and keep paste URL available.
- Import loading: disable the selected import button and keep the form stable.
- Import success: show a subtle success notice that summarizes filled and skipped fields.
- Inaccessible repo: explain whether it is not found, private, or rate-limited when known.
- Rate limited: ask the user to try again later or connect GitHub if not connected.

Overwrite behavior:

- First slice should fill empty fields only.
- If a field already has content, skip it and include a warning like "Kept your existing description."
- A later slice can add per-field review controls if needed.

Source attribution behavior:

- First slice should use a success notice and skipped-field summary instead of per-field source badges.
- Keep the `evidence` contract in the JSON response so source badges can be added later without changing the service contract.
- Per-field badges are useful for trust, but can make the already dense project form noisy before the interaction proves itself.

The UI should avoid visible tutorial copy about how the whole feature works. Keep the panel concise and action-oriented.

## AI / External Service Notes

The first implementation can avoid LLM calls.

Recommended first slice:

- Use deterministic GitHub metadata, README excerpts, languages, topics, manifests, and architecture signals.
- Use bounded README extraction only: prefer repo description, then README heading/opening excerpt. Do not summarize arbitrary README content with an LLM in the first slice.
- Generate conservative text through local templates.
- Clearly distinguish GitHub-derived evidence from user-authored claims.

Potential later slice:

- Add an optional "Draft story from repository" step using existing Project Story Builder patterns.
- Ground prompts only in the prefill payload, existing user-entered fields, and GitHub evidence.
- Return structured output for specific `project_story` fields.
- Require user review before applying.
- Reuse existing rate-limiting patterns from Project Story Builder.

External API considerations:

- Do not log OAuth tokens or raw Authorization headers.
- Keep API calls bounded.
- Prefer existing `GitHubInsights::FetchService` for repository payloads where practical.
- Add a lighter repository listing service for picker data.
- Cache connected-user repository list responses briefly, scoped by user, to reduce repeated GitHub API calls while avoiding stale long-lived private repo metadata.
- Recommended initial cache duration: 5 minutes.
- Do not cache OAuth tokens. Cache only normalized repository list payloads.
- Handle GitHub 401, 403, 404, and 5xx responses with user-safe messages.
- Avoid storing raw pre-save import payloads in the database unless needed for a later audit trail.

## Implementation Plan

1. Add a `GitHubProjectPrefillService` that accepts a repository URL and returns a form-ready prefill contract.
2. Add a lightweight GitHub repository listing service for connected users.
3. Add routes and controller actions for repo listing and prefill generation.
4. Add owner-only authorization and OAuth-connected checks.
5. Add a Stimulus controller for the import panel to fetch repos, fetch prefill data, and apply values into the existing form.
6. Add the import panel to `projects/new`, keeping manual project creation unchanged.
7. Add request/service tests for successful import, inaccessible repos, unauthenticated access, and non-overwrite behavior.
8. Verify the new project flow manually in browser for connected, disconnected, success, and failure states.
9. Update this brief with implementation decisions and verification results.

## Acceptance Criteria

- Authenticated users can still create projects manually without using GitHub import.
- Connected GitHub users can search/select a repository and apply a prefill draft to the new project form.
- The connected picker lists owner repositories only in the first slice.
- Forked repositories are hidden by default, or included only through an explicit filter if implemented.
- Users can paste a public GitHub repo URL and apply a prefill draft.
- Import fills deterministic fields such as title, description, source URL, live URL, and technologies when available.
- Import drafts only conservative story fields and leaves personal/contextual story fields blank unless a reviewed AI slice is added.
- Import does not save or publish a project automatically.
- Import does not overwrite non-empty user-entered form fields in the first slice.
- Imported GitHub projects default `project_insight_enabled` to true while keeping the form checkbox editable.
- Private repository import requires the current user's GitHub OAuth token.
- Failed imports show clear, non-secret error messages.
- Repository list responses are briefly cached per user without caching tokens.
- Existing post-save GitHub enrichment sync still runs for saved imported projects when enabled.
- Public visitors and other users cannot access another user's import data.

## Verification Plan

Targeted checks:

```bash
bin/rails test test/services/github_project_prefill_service_test.rb
bin/rails test test/controllers/projects_controller_test.rb
bin/rails test test/system/projects_test.rb
```

Existing nearby checks:

```bash
bin/rails test test/models/project_test.rb
bin/rails test test/services/github_insights/sync_service_test.rb
```

Baseline checks:

```bash
bin/rails db:migrate:status
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman
git status --short
```

Manual verification:

- Create project manually without using import.
- Import from a public repo by URL.
- Import from a connected account repo picker.
- Confirm non-empty form values are not overwritten.
- Confirm inaccessible/private repo errors do not reveal private data.
- Confirm saved imported project queues GitHub enrichment.

## Rollout / Revert Plan

Recommended rollout:

- Gate the feature behind the existing GitHub project enrichment rollout if the implementation can reuse that flag cleanly.
- If the UX needs independent control, add a new feature flag such as `GITHUB_PROJECT_IMPORT_ROLLOUT`.
- Start internal-only, then expand once picker and import errors are stable.

Revert plan:

- Remove or hide the import panel and routes behind the feature flag.
- Keep existing manual project creation untouched.
- Because the first slice does not require schema changes, revert should be low-risk.

## Open Questions

- [x] Should the picker include only owner repositories, or also organization repositories available through `read:org`? Decision: owner repositories only in the first slice.
- [x] Should forked repositories appear by default, or be hidden behind a filter? Decision: hide forks by default; include an explicit filter only if inexpensive.
- [x] Should `project_insight_enabled` default on after import, or should the user opt in explicitly? Decision: default on for imported GitHub repositories with valid repo URLs; keep checkbox editable.
- [x] Should imported fields display source badges in the first slice, or is a success notice enough? Decision: use a success/skipped-fields notice first; keep the evidence contract for later badges.
- [x] Should README summarization be deterministic only in Stage 6, or should a later AI slice be included before implementation completes? Decision: deterministic README extraction only in the first slice; optional reviewed AI drafting can be later.
- [x] Should repo list data be cached briefly to reduce GitHub API calls? Decision: yes, cache normalized per-user repo list payloads for about 5 minutes without caching tokens.

## Decision Log

- 2026-06-03: Use a full brief because the feature introduces a new user-facing workflow, OAuth-backed external integration behavior, and trust-sensitive GitHub-derived prefilling.
- 2026-06-03: First implementation should prefill the unsaved new project form and require user review before create.
- 2026-06-03: First implementation should avoid LLM calls and use deterministic GitHub evidence unless a later slice explicitly adds reviewed AI drafting.
- 2026-06-03: Connected picker should include only repositories owned by the authenticated GitHub user in the first slice.
- 2026-06-03: Forked repositories should be hidden by default, with an explicit include-forks filter only if the UI can support it cleanly.
- 2026-06-03: Imported GitHub projects should default Project Insight on while keeping the checkbox editable before save.
- 2026-06-03: First slice should use a success/skipped-fields notice instead of per-field source badges, while retaining an evidence contract for later UI.
- 2026-06-03: First slice should use deterministic README extraction only; LLM story drafting remains optional future scope.
- 2026-06-03: Repository list payloads should be cached per user for about 5 minutes; tokens must not be cached.

## Implementation Notes

- **Feature flag:** Reuses `GITHUB_PROJECT_ENRICHMENT_ROLLOUT` via `FeatureFlags.github_project_enrichment_enabled_for?` for import panel visibility and JSON endpoints.
- **Services:** `GitHubProjectPrefillService` (deterministic prefill contract) and `GitHubProject::RepositoryListService` (owner repos, 5-minute cache, forks hidden by default).
- **Routes:** `GET /projects/github_repositories`, `POST /projects/github_prefill` (authenticated, owner-only new-project flow).
- **UI:** `_github_import.html.erb` on `projects/new` with `github-project-import` Stimulus controller; fills empty fields only and summarizes filled/skipped fields.
- **Verification:** `bin/rails test test/services/github_project_prefill_service_test.rb test/services/github_project/repository_list_service_test.rb test/controllers/projects_controller_test.rb -n "/github/"` — 13 runs, 0 failures.

## Progress

- [x] Brief created.
- [x] Resolve initial product defaults for owner repos, forks, Project Insight, attribution UI, README handling, and repo-list caching.
- [x] Decide feature flag and rollout scope.
- [x] Implement GitHub project prefill service.
- [x] Implement repository listing service.
- [x] Add controller routes and authorization.
- [x] Add new project import panel and Stimulus behavior.
- [x] Add targeted tests.
- [x] Run targeted and baseline verification.
- [x] Update this brief with final implementation decisions and verification results.
