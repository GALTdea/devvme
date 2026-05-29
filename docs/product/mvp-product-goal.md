# DevvMe MVP Product Goal

**Status:** Active MVP reference  
**Owner:** Gustavo  
**Created:** 2026-05-29  
**Related Strategy:** `docs/product/strategy-2026.md`  

## Purpose

This document describes the MVP destination for DevvMe's repositioning into an AI-powered proof-of-work platform for developers.

Use this as the product north-star reference for feature stages, implementation briefs, UI decisions, AI behavior, and scope tradeoffs.

The strategy doc explains the direction. This MVP doc defines the first complete product version we are trying to reach.

## MVP Goal

DevvMe MVP helps a developer turn at least one real project into a clear, public, shareable proof-of-work story.

The MVP is successful when a developer can:

1. Sign in.
2. Connect GitHub or manually create a project.
3. Add structured story context about the project.
4. Use AI assistance to improve or generate a project story from real inputs.
5. Review and edit the story.
6. Publish the story on a public project page.
7. Show that story on their public profile.
8. Generate resume bullets from the story.
9. Share the profile or project story externally.

The MVP should make the user feel:

```text
I finally have a clear, credible way to explain what I built and why it matters.
```

## MVP Success Test

The MVP is successful if a developer can complete this path in one session:

1. Create or select one real project.
2. Add rough project context.
3. Use AI to improve or generate a structured project story.
4. Review and edit the result.
5. Publish the public project story.
6. Generate resume bullets from the story.
7. Share the public project story link.

The user should not need to understand every DevvMe feature to complete this path.

## North-Star Question

Every MVP-stage decision should be evaluated by this question:

```text
Does this help a developer turn real work into public proof?
```

If a feature does not support that loop, it should be delayed, hidden, simplified, or treated as secondary.

## Target User

The MVP is for developers who have built real things but struggle to explain them clearly.

Primary users:

- Early-career developers with side projects
- Career changers building proof of ability
- Independent developers and freelancers
- Open-source contributors
- Developers preparing for job search, interviews, promotion, or client discovery

The MVP should assume the user may have useful work but rough storytelling.

## Core MVP Loop

```text
Connect work -> Build project story -> Publish proof -> Generate resume bullets -> Share externally
```

The MVP should make this loop obvious from the dashboard and project flow.

## MVP User Journey

### 1. Start

The developer signs in and understands quickly that DevvMe helps them explain and share their work.

Minimum expectations:

- The dashboard points them toward creating or improving a project story.
- The product language emphasizes proof-of-work, not generic portfolio completion.
- Secondary features do not compete with the main action.

### 2. Add Work

The developer connects GitHub or manually creates a project.

Minimum expectations:

- A project can be created without GitHub.
- GitHub links enrich the story when available.
- Existing project CRUD, draft/publish/archive, ordering, links, images, and technologies continue to work.

### 3. Build Story

The developer adds structured project-story context.

Minimum expectations:

- Story sections are optional at first.
- The form guides the developer with practical prompts.
- The existing description remains separate and can act as fallback.
- The story structure is stored in a versioned `project_story` JSONB field on `projects`.
- The existing `description` field should remain the short project/card description.
- The richer project story should live in the versioned `project_story` structure.
- Public project pages may fall back to `description` when `project_story["overview"]` is blank.

MVP story section contract:

- Overview
- Problem solved
- Intended users
- Why it was built
- Developer's role
- Key technical decisions
- Hardest challenge
- Lessons learned
- What the project demonstrates
- Promotion notes

All sections are optional for saving and publishing during early MVP stages. The UI should encourage completion but should not block users.

The UI may group these into core prompts and optional supporting prompts so the form does not feel heavy. Core prompts should include overview, problem solved, developer's role, key technical decisions, hardest challenge, lessons learned, and what the project demonstrates. Intended users and why it was built may be treated as supporting prompts.

`promotion_notes` exists in the current Stage 1 implementation, but it should be treated as an optional supporting/internal prompt rather than a core MVP story section. Resume bullets should be generated from the main story fields; promotion and social notes can come later.

### 4. Improve With AI

The developer can ask DevvMe to help turn rough project context into clearer public proof.

Minimum expectations:

- AI uses project story fields, project metadata, and GitHub-derived signals when available.
- AI asks for missing context or leaves uncertainty visible rather than inventing details.
- AI distinguishes user-provided claims from GitHub-derived evidence.
- The developer reviews and edits generated output before publishing.

For MVP, AI assistance should focus first on helping the developer improve or generate the project story from real project inputs.

The first required reusable AI asset is resume bullets generated from the project story.

Other outputs, such as interview talking points, recruiter summaries, LinkedIn drafts, and X/Twitter drafts, are useful but should not delay the core MVP loop.

### 5. Publish Proof

The developer publishes the project story publicly.

Minimum expectations:

- Public project pages render structured story sections cleanly.
- Empty sections do not appear as awkward blank UI.
- GitHub-derived evidence remains visually separate from user-written story content.
- Existing Project Insight naming can remain unchanged during MVP buildout.
- Public URLs remain stable.

### 6. Show Profile

The public developer profile presents the developer through proof-of-work.

Minimum expectations:

- The profile highlights project stories as the main proof surface.
- The profile feels like a developer-centered narrative, not a plain resume clone.
- Blog, follows, and digest features are secondary unless they support proof-of-work discovery.

### 7. Generate Assets

The developer can reuse project-story content outside DevvMe.

Minimum expectations:

- The MVP must generate at least one reusable asset from the project story.
- The first required reusable asset is resume bullets.
- Interview talking points are the preferred second asset if implementation is straightforward.
- Social post generation should be deferred unless it can be added without delaying the core project-story loop.

Rationale: resume bullets should ship first because they are directly useful, grounded in the project story, and valuable for early-career/job-seeking users. Interview talking points are second priority. Social posts should come after the project-story and resume-bullet loop is stable.

Resume bullets should be project-specific bullets only. DevvMe should not attempt to generate or manage a full resume in the MVP.

### 8. Share

The developer can share the profile or project story externally.

Minimum expectations:

- Public project story pages have useful metadata and social preview behavior.
- Existing Open Graph/Twitter card support is reused where possible.
- Sharing should support job search, interviews, social posting, and professional discovery.
- Basic sharing must exist in the MVP through public URLs and useful social preview metadata.
- Broader discovery features, such as featured stories, advanced Explore filters, technology directories, and community pages, should come later after there is enough strong project story content.

## MVP In Scope

- Proof-of-work product language
- Project story fields and rendering
- Public project story pages
- Public profile emphasis on project stories
- GitHub evidence reuse when available
- AI-assisted story improvement
- Resume bullet generation from grounded project-story data
- Social/share metadata for project stories
- Basic story completeness guidance
- Migration-safe updates to existing projects

GitHub evidence reuse means displaying or referencing existing GitHub-derived signals where already available. MVP does not require a major GitHub Insights rebuild.

## MVP Out of Scope

- Full social network mechanics
- Making blog central to the product loop
- Email digest as a core MVP feature
- Advanced discovery directories
- Paid marketplace/community features
- Full resume builder
- Full applicant tracking or job-search CRM
- Multi-provider VCS support beyond current GitHub direction
- Rebuilding the app from scratch
- Broad AI writing tools unrelated to a real project story
- Version history for project stories
- Story scoring that feels judgmental or competitive

## Do Not Accidentally Build

During MVP work, do not accidentally turn DevvMe into:

- A full resume builder
- A full social network
- A job board
- A recruiter marketplace
- A blogging platform
- A generic AI writing app
- A GitHub analytics dashboard

These may be useful later, but the MVP is only about turning one real project into public proof-of-work.

## MVP Product Surfaces

### Dashboard

Primary job:

- Guide the developer toward creating, improving, and publishing project stories.

Secondary job:

- Show story/profile completeness and next best actions.

### Project Form

Primary job:

- Capture structured proof-of-work context without overwhelming the user.

### Public Project Page

Primary job:

- Present one project as credible proof of ability.

### Public Profile

Primary job:

- Present the developer through their best proof-of-work.

### AI Builder / Story Assistant

Primary job:

- Help turn rough project context into clear story content and resume bullets.

### Sharing / Social Preview

Primary job:

- Make proof-of-work easy to share outside DevvMe.

## MVP Stages

### Stage 1: Project Stories Foundation

Status: Completed in the current implementation branch.

Reference:

- `docs/features/completed/project-stories-stage-1.md`

Goal:

- Add versioned project-story structure.
- Update project forms.
- Render story sections publicly.
- Keep existing GitHub evidence visually separate.

### Stage 2: Dashboard and Profile Reframe

Goal:

- Make the product feel like a proof-of-work platform from the first signed-in moment.
- Reframe profile/project language around proof-of-work.
- Point users toward improving or publishing project stories.

Likely outputs:

- Dashboard next-step guidance
- Story completeness indicators
- Public profile emphasis on project stories
- Reduced prominence for secondary social/blog surfaces

### Stage 3: AI Project Story Assistant

Goal:

- Help developers generate and improve project stories from real inputs.

Likely outputs:

- Guided story questions
- AI rewrite/generation flow
- Review-before-publish behavior
- Evidence-aware generation rules

### Stage 4: Promotion Assets

Goal:

- Turn published project stories into reusable career/promotion assets.

Likely outputs:

- Resume bullets
- Interview talking points if straightforward
- Recruiter-friendly summary, LinkedIn drafts, and X/Twitter drafts later

### Stage 5: Sharing and Discovery Polish

Goal:

- Make proof-of-work pages easier to share first, then discover later.

Likely outputs:

- Public URLs and useful social preview metadata for MVP sharing
- Stronger social preview cards
- Featured project stories after enough strong story content exists
- Explore surfaces centered on proof-of-work later
- Technology/topic discovery only after enough good story content exists

## Acceptance Criteria For MVP

MVP can be considered reached when:

- A new user can create or import a project.
- A user can add structured project-story content.
- A user can publish a readable public project story.
- A public profile highlights project stories as proof-of-work.
- AI can help improve or generate project-story content without fabricating unsupported claims.
- A user can generate resume bullets from a project story.
- A user can share a public profile or project story with useful preview metadata.
- Existing project/profile data remains intact.
- Secondary features do not obscure the core proof-of-work loop.

## Quality Bar

The MVP should feel:

- Clear
- Practical
- Developer-centered
- Encouraging
- Credible
- Polished enough to share publicly
- Lightly playful without becoming unserious

The MVP should not feel:

- Corporate
- Fake
- Like a generic resume builder
- Like a generic social network
- Like AI is inventing a developer's accomplishments

## AI Rules For MVP

AI must:

- Ground output in user-provided project story data, project metadata, and GitHub-derived signals when available.
- Ask for missing context when needed.
- Preserve the developer's voice and intent.
- Avoid exaggeration and unsupported claims.
- Avoid inventing metrics, users, outcomes, employers, credentials, or impact.
- Label or separate evidence-derived observations from user-authored claims.
- Give the developer final review/edit control.
- AI-generated project story or resume bullet content should not overwrite existing user-authored content without user review/confirmation.

## Open Product Questions

- [x] Which promotion asset should ship first: resume bullets, interview talking points, recruiter summary, or social post?

  Decision: Resume bullets should ship first because they are directly useful, grounded in the project story, and valuable for early-career/job-seeking users. Interview talking points are the second priority. Social posts should follow after the project-story and resume-bullet loop is stable.

- [x] Should the AI story assistant be part of Project Insight, Career Architect, or a newly named Story Builder?

  Decision: The user-facing MVP feature should be named Project Story Builder or Story Builder.

  It may reuse existing Career Architect services/sessions internally, but the product surface should be project-centered rather than career-chat-centered.

  Project Insight should remain separate for visitor/project Q&A.

  Preference:

  - User-facing name: Project Story Builder
  - Internal strategic category: proof-of-work platform

- [x] What is the minimum story completeness signal that is helpful without becoming annoying?

  Decision: Use a lightweight checklist instead of aggressive scoring.

  The minimum useful signal is whether the project has an overview, problem, role, challenge, lesson, and demonstration statement.

  Show completeness as guidance, not judgment.

  Good example:

  ```text
  Your story has 3 of 6 helpful sections.
  ```

  Avoid:

  ```text
  Your story score is 47/100.
  ```

- [x] Should project stories support multiple published versions later?

  Decision: Multiple published versions are out of scope for MVP.

  The MVP should support one current project story per project.

  The storage design should not prevent future versioning, but no version UI or revision history is required now.

- [x] What should be the first discovery surface once enough strong project stories exist?

  Decision: The first discovery surface should be a curated Featured Project Stories section.

  This is easier to control for quality than a broad directory and supports the proof-of-work narrative better.

  Explore filters and technology directories can come later.

## Final MVP Framing

The MVP should stay focused on the smallest complete proof-of-work loop: one developer creates or selects one real project, turns it into one structured public story, generates one practical reusable asset, and shares one public link.
