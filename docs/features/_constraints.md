# DevvMe Feature Constraints

These constraints apply to AI-assisted development unless a feature brief explicitly changes them.

## Product

- DevvMe is a developer portfolio and professional presence platform.
- Recruiter, hiring-manager, and professional credibility use cases matter.
- AI-generated content should be grounded in user-provided profile/project/GitHub evidence where possible.
- User trust is more important than impressive but unsupported claims.

## Rails Architecture

- Prefer conventional Rails structure.
- Keep controllers focused on request handling.
- Put domain behavior in models, services, jobs, policies, or query objects as appropriate.
- Use background jobs for slow external calls and AI/GitHub work.
- Avoid broad rewrites unless the feature brief calls for them.

## Authorization and Access

- Use Pundit for authorization.
- Preserve account status checks, admin boundaries, and user ownership boundaries.
- Admin and super-admin behavior must remain explicit and auditable.
- Do not expose private user data through public profile, project, or AI surfaces.

## Data Model

- Use migrations for schema changes.
- Do not hand-edit `db/schema.rb`.
- Add indexes for foreign keys and common lookup/order columns.
- Prefer json/jsonb only when the shape is flexible, external, or intentionally versioned.
- Document new durable JSON contracts in the feature brief or architecture docs.

## AI Features

- Keep prompts and outputs honest about uncertainty.
- Do not invent user experience, skills, credentials, or repository evidence.
- Bound input and output size.
- Consider cost, rate limits, abuse, and failure states.
- Prefer structured outputs when downstream behavior depends on parsing.
- Store only the data needed for the product behavior.

## GitHub and External Integrations

- Do not log tokens or secrets.
- Prefer asynchronous sync for network-bound work.
- Handle rate limits and API failures gracefully.
- Make private repository access explicit and owner-controlled.
- Use compact normalized snapshots instead of mirroring whole repositories.

## Frontend

- Prefer Hotwire/Turbo and Stimulus for interactivity.
- Use Tailwind and Flowbite patterns already present in the app.
- Keep UI dense enough for product workflows and polished enough for public portfolio surfaces.
- Avoid custom CSS unless the existing utility/component system is insufficient.
- Test important user flows with controller, integration, or system tests.

## Testing

- This project uses Minitest under `test/`.
- Add or update tests for new behavior.
- Use targeted tests during development and broader checks before handoff.
- Security-sensitive changes require policy/controller tests and Brakeman.

## Documentation

- Feature intent belongs in feature briefs.
- Cross-cutting decisions belong in `docs/decisions/`.
- Architecture references belong in `docs/architecture/`.
- Update docs when product direction, architecture, data contracts, or operational behavior changes.

