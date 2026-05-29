# Verification Reference

DevvMe uses Minitest. Use `bin/rails test`, not RSpec, unless the project intentionally adopts RSpec later.

## Baseline Checks

Run these before merge or major handoff:

```bash
bin/rails db:migrate:status
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman
git status --short
```

## Targeted Checks

Use targeted checks while working in small slices:

```bash
bin/rails test test/models/project_test.rb
bin/rails test test/controllers/projects_controller_test.rb
bin/rails test test/services/architect_service_test.rb
bin/rails test test/services/github_insights/sync_service_test.rb
bin/rails test test/jobs/git_hub_insights_sync_job_test.rb
```

## When Changing Views or Stimulus

Prefer the closest controller/system/integration tests first:

```bash
bin/rails test test/controllers/public_profiles_controller_test.rb
bin/rails test test/system/projects_test.rb
bin/rails test test/javascript/controllers/share_button_controller_test.js
```

Then run broader checks if the change affects shared layout, navigation, or JavaScript behavior.

## When Changing Data Model

Required checks:

```bash
bin/rails db:migrate:status
bin/rails test test/models
bin/rails test
```

Also inspect generated schema changes before handoff.

## When Changing Security or Auth

Run focused controller/policy tests plus security scanning:

```bash
bin/rails test test/policies
bin/rails test test/controllers
bin/brakeman
```

## Handoff Format

Record:

- Commands run
- Commands skipped
- Failures encountered
- Whether failures are related to the change

