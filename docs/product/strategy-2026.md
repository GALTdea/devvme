# DevvMe Strategy 2026

**Status:** Active direction  
**Owner:** Gustavo  
**Purpose:** Capture the product direction for DevvMe before major implementation work begins.

## Core Product Goal

Help developers turn real technical work into clear, public proof-of-work.

DevvMe should become an AI-powered proof-of-work platform for developers. The product should help developers turn GitHub repositories, side projects, open-source contributions, experiments, shipped apps, and technical projects into clear, honest, public, shareable proof-of-work.

## North Star

Every important product decision should be evaluated by this question:

Does this help a developer turn real work into public proof?

If yes, it may belong in the core product. If no, it should be delayed, hidden, simplified, or treated as secondary.

## Current Product

DevvMe is currently a Rails-based developer portfolio platform with public profiles, project showcases, blog posts, analytics, AI-assisted profile generation, GitHub-backed project insights, invitations, social preview cards, and lightweight community/distribution features.

The current app should not be rebuilt from scratch. Existing capabilities should be reused and redirected toward the proof-of-work loop.

## What Is Changing

DevvMe is no longer primarily a generic portfolio builder, blogging platform, or social network.

The new product focus is:

- Developer identity
- Project stories
- Proof-of-work
- AI-assisted explanation
- Shareable career and promotion assets
- GitHub-enriched profiles
- Public project pages
- Developer discovery once enough strong content exists

The product should help a developer go from:

```text
I built this project.
```

to:

```text
Here is a clear, structured story explaining what I built, why it matters, what decisions I made, what I learned, and what this project proves about me.
```

## What We Are No Longer Optimizing For

These concepts may still exist, but they should not drive core product decisions:

- Generic portfolio building
- Blogging as a central product loop
- Follower/following mechanics as a primary loop
- Email digests before there is enough useful proof-of-work content
- Social network behavior that distracts from explaining real work
- AI-generated polish that is not grounded in real user work

## Primary User

The primary user is a developer who has built real things but needs help explaining, packaging, and sharing that work.

This includes:

- Early-career developers with side projects
- Career changers building a body of work
- Independent builders and freelancers
- Open-source contributors
- Developers preparing for job search, interviews, promotion, or client discovery

## Core Workflow

The ideal core user flow is:

1. Developer signs in.
2. Developer connects GitHub or manually adds a project.
3. Developer selects a project they want to showcase.
4. DevvMe asks guided questions about the project.
5. AI helps generate a structured project story.
6. Developer reviews and edits the generated content.
7. Developer publishes the project story to their public profile.
8. Developer generates reusable assets from the story:
   - Resume bullets
   - LinkedIn post
   - X/Twitter posts
   - Interview talking points
   - Short profile summary
9. Developer shares the profile or project story externally.
10. DevvMe continues guiding the developer to improve their profile over time.

The core loop is:

```text
Connect work -> Generate story -> Publish proof -> Share externally -> Improve over time
```

## Product Pillars

### 1. Developer Identity

The public developer profile should answer:

- Who is this developer?
- What kind of work do they do?
- What are they building?
- What technologies do they use?
- What work are they proud of?
- Are they open to work, collaboration, or clients?

The profile should not feel like a plain resume clone. It should feel like a readable, human, developer-centered story.

### 2. Proof-of-Work

Projects should become structured proof-of-work stories, not just cards with descriptions.

A strong project story should explain:

- Project overview
- Problem solved
- Intended users
- Why it was built
- Developer's role
- Tech stack
- Key technical decisions
- Hardest challenge
- What the developer learned
- What the project demonstrates
- GitHub, live demo, screenshots, and relevant links

This should become the most important content type in the app.

### 3. AI-Assisted Promotion Tools

AI should help developers explain, structure, rewrite, and package their work. AI should assist the developer, not replace their voice or invent accomplishments.

AI should help generate:

- Project stories
- Developer bios
- Profile headlines
- Resume bullets
- LinkedIn posts
- X/Twitter posts
- Interview talking points
- Recruiter-facing summaries
- Plain-English explanations of technical work

AI must avoid exaggerating, fabricating, or overstating the developer's work.

### 4. Distribution

DevvMe should help developers get their work seen.

Distribution can include:

- Public profiles
- Public project story pages
- Share links
- Social cards
- Explore pages
- Featured developers
- Featured project stories
- Technology directories
- Newsletters or digests later
- Community or partner pages later

Distribution matters, but it should support the proof-of-work loop rather than distract from it.

## Product Reframes

Existing product concepts should be reframed:

- "Portfolio" becomes "proof-of-work profile"
- "Project" becomes "project story" when published publicly
- "Career Architect" may become "Proof-of-Work Builder" or "Developer Story Builder"
- "Profile completion" may become "story completeness"
- "Blog" becomes secondary
- "Followers/following" becomes secondary
- "Email digest" becomes secondary until there is enough useful content

## Existing Capabilities To Reuse

The current app already includes useful building blocks:

- Rails 8 monolith
- Devise authentication
- GitHub OAuth
- Public developer profiles at `/:username`
- Project CRUD
- Project publishing and drafting
- Project ordering
- Blog posts and public blog
- Public Explore pages
- Followers/following
- Email digest system
- Admin dashboards
- Invitation/claiming system
- Social preview cards
- Open Graph/Twitter card support
- SEO helpers
- Sitemap
- Career Architect AI backend
- Project Insight Q&A
- GitHub Insights
- Analytics and visitor tracking

The work should focus on:

- Aligning the existing app to the new product direction
- Simplifying the core user journey
- Exposing the AI proof-of-work workflow clearly
- Improving public project story pages
- Improving sharing and promotion assets
- Cleaning up confusing or stale areas
- Demoting non-core features in the UI

## Desired Product Experience

A new user should quickly understand:

- DevvMe helps me explain my work.
- DevvMe helps me turn projects into proof.
- DevvMe helps me create useful public project stories.
- DevvMe helps me generate resume, social, and interview assets.
- DevvMe helps me share my work better.

The product should feel:

- Clear
- Friendly
- Practical
- Developer-centered
- Encouraging
- Polished
- Lightly playful
- Not corporate
- Not fake
- Not overly social-network oriented

## AI Behavior Guidelines

AI inside DevvMe should:

- Clarify the developer's work
- Structure messy project descriptions
- Ask for missing context when needed
- Help rewrite rough notes into polished copy
- Preserve the developer's intent
- Avoid exaggeration
- Avoid fabrication
- Avoid fake outcomes
- Avoid claiming skills not supported by the user's input
- Distinguish between GitHub-derived data and user-provided claims

## Technical Implications

Expected implementation themes:

- Treat the project story as the central content object or content shape.
- Reuse existing project, GitHub Insights, Project Insight, and Career Architect systems where practical.
- Add structured story fields or versioned JSON contracts only with clear briefed rationale.
- Create guided project-story generation flows before adding broad new community features.
- Make public project pages richer and more shareable.
- Generate reusable promotion assets from grounded project-story data.
- Demote or simplify blog, follows, and digest surfaces where they compete with the proof-of-work loop.
- Keep AI/GitHub work asynchronous, bounded, and transparent about evidence.

## Migration / Refactor Themes

Likely tracks:

- Project pages -> project story pages
- Career Architect -> proof-of-work/story builder direction
- Profile completion -> story/profile completeness
- GitHub Insights -> evidence engine for stories and public proof
- Social cards -> story/profile distribution assets
- Explore/featured -> discovery for strong proof-of-work content
- Blog/follows/digests -> secondary supporting surfaces

## Open Questions

- [ ] Should "project story" be stored as structured columns, JSON, Action Text, or a hybrid?
- [ ] Should the current Career Architect be renamed or replaced by a broader Story Builder?
- [ ] What is the first implementation slice for the proof-of-work loop?
- [ ] Which existing public pages should be redesigned first: profile, project, or dashboard onboarding?
- [ ] How should manually entered project stories and GitHub-derived evidence be visually distinguished?
- [ ] What promotion assets should v1 generate first?

## Decisions Made

- 2026-05-29: DevvMe's north star is to help developers turn real work into public proof.
- 2026-05-29: Existing app capabilities should be reused and redirected rather than rebuilt from scratch.
- 2026-05-29: Blog, follows, and email digest features are secondary until they support the proof-of-work loop.

