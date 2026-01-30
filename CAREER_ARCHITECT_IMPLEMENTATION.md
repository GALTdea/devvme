# Career Architect - Implementation Tracking

**Feature:** AI-powered profile builder that guides developers through a Socratic interview to generate compelling bios, headlines, and profile content.

**Status:** 🔴 Not Started  
**Start Date:** TBD  
**Target Completion:** TBD

---

## Design Decisions

### 1. Branding: "Architect" vs "Mentor"
- **Choice:** Career Architect
- **Rationale:** Aligns with dev/builder theme; implies construction vs generic advice
- **Naming:** `ArchitectSession`, `ArchitectMessage`, `ArchitectService`

### 2. Chat as Training Data
- **Choice:** Store messages with `topic`, `insight_type`, `metadata` fields
- **Rationale:** Enables future "Agentic Twin" feature by preserving user's professional knowledge graph
- **Future Use:** Query messages for recruiter-facing chatbot context

### 3. Async Processing
- **Choice:** Solid Queue jobs + Turbo Stream broadcasts
- **Rationale:** Prevents browser hangs (LLM calls take 3-10s); creates ChatGPT-like real-time feel
- **Implementation:** Controller saves message → job calls LLM → broadcasts result

### 4. Hybrid Model Strategy
- **Choice:** Fast model (gpt-4o-mini) for Q&A; premium model (claude-3-5-sonnet) for final generation
- **Rationale:** 5x cost savings; faster UX during conversation
- **Estimated Cost:** ~$0.06 per session (vs $0.30+ with single premium model)

---

## Phase 1: Foundation (MVP)

### Database & Models

- [x] **Step 1: Create migrations**
  - Status: ✅ Done
  - Files: `db/migrate/20260129120000_create_architect_sessions.rb`, `db/migrate/20260129120001_create_architect_messages.rb`
  - Notes: Include `topic`, `insight_type`, `metadata` for future training data use
  - **Schema:**
    ```ruby
    # architect_sessions
    - user_id (references users)
    - status (string: draft, in_progress, completed, abandoned)
    - goal (string: bio, headline, both)
    - context_snapshot (jsonb)
    - generated_bio (text)
    - generated_headline (text)
    - question_count (integer, default: 0)
    - timestamps

    # architect_messages
    - architect_session_id (references architect_sessions)
    - role (string: user, assistant)
    - content (text)
    - sequence (integer)
    - topic (string, nullable)
    - insight_type (string, nullable)
    - metadata (jsonb, default: {})
    - timestamps
    ```

- [x] **Step 2: Create models**
  - Status: ✅ Done
  - Files: `app/models/architect_session.rb`, `app/models/architect_message.rb`
  - Dependencies: Step 1
  - Notes: Add associations, validations, enums; update User model

- [x] **Step 3: Create Pundit policies**
  - Status: ✅ Done
  - Files: `app/policies/architect_session_policy.rb`, `app/policies/architect_message_policy.rb`
  - Dependencies: Step 2
  - Notes: Only session owner can access

---

### AI Integration

- [x] **Step 4: Add LLM gems**
  - Status: ✅ Done
  - Gems: `ruby-openai`, `anthropic`
  - Files: `Gemfile`, `config/environment.example`, `README.md`
  - Notes: Store API keys in credentials or ENV; documented in README and environment.example

- [x] **Step 5: Create ArchitectService**
  - Status: ✅ Done
  - File: `app/services/architect_service.rb`
  - Dependencies: Step 2, Step 4
  - Methods:
    - `start_session(user, goal, pasted_content: nil)` - Initialize session with context
    - `reply(session)` - Process next message with fast model
    - `finalize(session)` - Generate final bio/headline with premium model
    - `build_context(user, pasted_content)` - Extract profile + projects data
  - Notes: System prompts for Socratic interviewing; token limit management

- [x] **Step 6: Create background job**
  - Status: ✅ Done
  - File: `app/jobs/architect_reply_job.rb`
  - Dependencies: Step 5
  - Notes: Turbo Stream broadcast; retry logic; error handling

---

### Controllers & Routes

- [x] **Step 7: Create controllers**
  - Status: ✅ Done
  - Files: `app/controllers/architect/sessions_controller.rb`
  - Dependencies: Step 5, Step 6
  - Actions: `new`, `create`, `show`, `message`, `accept`, `destroy`
  - Notes: Rate limiting (3 sessions/hour, 20 messages/session); Turbo Stream for `message`; Pundit authorize on all actions; locale keys in `config/locales/en.yml`; thinking indicator partial for message response

- [x] **Step 8: Add routes**
  - Status: ✅ Done
  - File: `config/routes.rb`
  - Dependencies: Step 7
  - Routes:
    ```ruby
    namespace :architect do
      resources :sessions, only: [:new, :create, :show, :destroy] do
        member do
          post :message
          patch :accept
        end
      end
    end
    ```

---

### UI & UX

- [x] **Step 9: Create chat UI**
  - Status: ✅ Done
  - Files:
    - `app/views/architect/sessions/show.html.erb`
    - `app/views/architect/messages/_message.html.erb`
    - `app/javascript/controllers/architect_chat_controller.js` (Stimulus)
  - Dependencies: Step 7, Step 8
  - Features: Turbo Stream subscription; message list; auto-scroll; "thinking" indicator

- [x] **Step 10: Create session start flow**
  - Status: ✅ Done
  - Files:
    - `app/views/architect/sessions/new.html.erb` (or modal)
    - Dashboard CTA button
  - Dependencies: Step 7, Step 8
  - Features: Goal selection; optional paste field; create and redirect

- [x] **Step 11: Create acceptance flow**
  - Status: ✅ Done
  - Files: `app/views/architect/sessions/_review_panel.html.erb`
  - Dependencies: Step 7, Step 8
  - Features: Preview bio/headline; "Accept", "Edit & Accept", "Discard" buttons

---

### Testing the Career Architect UI (Steps 9–11)

**1. Start the app and job worker**

```bash
# Terminal 1: web + Tailwind
bin/dev

# Terminal 2: Solid Queue (so ArchitectReplyJob runs and Turbo Streams deliver replies)
bin/jobs
```

Without `bin/jobs`, the chat will show "Thinking..." but assistant replies will never appear (the job never runs).

**2. Sign in**

Use a user that can access the dashboard (e.g. local account or seed user).

**3. Test without LLM API keys (UI only)**

- **Dashboard:** Open dashboard → you should see the **Career Architect** card in Quick Actions (first card).
- **Start flow:** Click it → `/architect/sessions/new` → choose goal (Bio only / Headline only / Bio and headline), optionally paste text → **Start session**.
- Without `OPENAI_API_KEY` and `ANTHROPIC_API_KEY` in env/credentials, create will redirect with "Career Architect is not configured" (or the job will fail and broadcast an error into the chat). So either set dummy session in DB or skip create and go to show manually (see below).
- **Chat UI (direct URL):** If you have an existing session ID, open `/architect/sessions/:id` → you should see the chat layout (message list, thinking slot, message form if session is in progress). Form submit will enqueue a job; with `bin/jobs` running but no keys, the job will broadcast an error and replace the thinking indicator with the error message.

**4. Test with LLM API keys (full flow)**

- Set `OPENAI_API_KEY` and `ANTHROPIC_API_KEY` (e.g. in `.env` or `config/credentials`) per `config/environment.example`.
- **Start session:** Dashboard → Career Architect → choose goal (and optional paste) → **Start session** → redirect to chat.
- **Chat:** First assistant message may appear after a short delay (job runs). Type a reply → **Send** → your message appears, "Thinking..." shows, then (with `bin/jobs` running) the assistant reply appears via Turbo Stream and the list auto-scrolls.
- **Complete:** After the interview completes, the thinking indicator is replaced by the **review panel**: preview of generated bio/headline, **Accept**, **Edit & Accept**, **Discard**.
- **Accept:** Updates profile and redirects to profile (or to edit profile if you used **Edit & Accept**). **Discard:** Asks for confirmation, then deletes the session and redirects to dashboard.

**5. Quick UI check without completing an interview**

- Create a session and open its show page. You can confirm: message list, scroll area, message form, End session button, and (after a refresh while the last message is from the user) the thinking indicator. To see the review panel without running the real interview, temporarily mark a session completed and set `generated_bio` / `generated_headline` in the console, then reload the show page.

---

### Security & Performance

- [ ] **Step 12: Rate limiting**
  - Status: ⚪ Not Started
  - File: `app/controllers/architect/sessions_controller.rb` (before_action)
  - Notes: Max 3 sessions/hour; max 20 messages/session; flash error messages

- [ ] **Step 13: Error handling**
  - Status: ⚪ Not Started
  - Files: `app/jobs/architect_reply_job.rb`, views for error states
  - Notes: Retry logic; user-friendly errors; admin notifications (optional)

- [ ] **Step 14: Testing**
  - Status: ⚪ Not Started
  - Files:
    - `test/models/architect_session_test.rb`
    - `test/models/architect_message_test.rb`
    - `test/services/architect_service_test.rb` (mock LLM)
    - `test/controllers/architect/sessions_controller_test.rb`
    - `test/policies/architect_session_policy_test.rb`
    - `test/integration/architect_flow_test.rb`
  - Dependencies: All previous steps

---

### Documentation & Launch

- [ ] **Step 15: Update documentation**
  - Status: ⚪ Not Started
  - Files: `docs/DATA_MODEL.md`, `README.md`, `CAREER_ARCHITECT_IMPLEMENTATION.md` (this file)
  - Notes: Document architecture, costs, and usage

- [ ] **Step 16: Soft launch**
  - Status: ⚪ Not Started
  - Dependencies: All previous steps
  - Notes: Enable for beta users; monitor Solid Queue; track costs and success rates

---

## Phase 2: Enhanced Context (Future)

- [ ] **Step 17: GitHub integration**
  - Status: ⚪ Not Started
  - Approach: OAuth or URL-based fetch
  - Notes: Enrich context with repos, README, profile

- [ ] **Step 18: LinkedIn paste enhancement**
  - Status: ⚪ Not Started
  - Notes: Parse LinkedIn HTML/text for structured data

- [ ] **Step 19: Message categorization**
  - Status: ⚪ Not Started
  - Notes: Background job to tag old messages with topics

---

## Phase 3: Expanded Use Cases (Future)

- [ ] **Step 20: Project Highlights**
  - Status: ⚪ Not Started
  - Notes: New goal type; generate project descriptions

- [ ] **Step 21: About Me (long form)**
  - Status: ⚪ Not Started
  - Notes: New goal type; generate narrative content

- [ ] **Step 22: Agentic Twin foundation**
  - Status: ⚪ Not Started
  - Notes: Use architect messages as "memory" for recruiter chatbot

---

## Technical Architecture

### Data Flow

```
User Dashboard
    ↓
  [Start Session] → Create ArchitectSession with context_snapshot
    ↓
  Chat UI (Turbo Stream subscription)
    ↓
  User sends message → Controller saves → ArchitectReplyJob.perform_later
    ↓
  Job calls ArchitectService.reply (fast model: gpt-4o-mini)
    ↓
  LLM returns next question OR "INTERVIEW_COMPLETE"
    ↓
  If complete: ArchitectService.finalize (premium model: claude-3-5-sonnet)
    ↓
  Job broadcasts Turbo Stream with new message
    ↓
  User sees message in real-time
    ↓
  [Accept] → Update user.bio / user.headline → Redirect to dashboard
```

### Context Snapshot Structure

```json
{
  "user_profile": {
    "full_name": "...",
    "job_title": "...",
    "location": "...",
    "skills": [...],
    "github_url": "...",
    "linkedin_url": "..."
  },
  "projects": [
    {
      "title": "...",
      "description": "...",
      "technologies_used": [...]
    }
  ],
  "pasted_content": "..."
}
```

### Model Strategy

| Phase | Model | Cost per 1M tokens | Use Case |
|-------|-------|-------------------|----------|
| Q&A Loop | gpt-4o-mini | $0.15 | Fast, cheap Socratic questions |
| Final Generation | claude-3-5-sonnet | $3.00 | High-quality bio/headline writing |

**Estimated Cost per Session:** ~$0.06 (5 Q&A rounds + 1 final generation)

---

## Success Metrics

- [ ] Average session completion rate > 70%
- [ ] Average LLM response time < 5s (for Q&A), < 10s (for final)
- [ ] User satisfaction: "Accept" rate > 60%
- [ ] Cost per completed session < $0.10
- [ ] Zero job failures from LLM errors (after retries)

---

## Known Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| LLM API downtime | Retry logic; user-friendly error; graceful degradation |
| High costs from abuse | Rate limiting; session/message caps; cost monitoring |
| Poor quality output | Premium model for final generation; allow re-generation |
| Slow UX | Async jobs + Turbo Streams; fast model for Q&A |
| Data privacy | Store context_snapshot encrypted; clear retention policy |

---

## Notes & Decisions Log

### 2026-01-29
- Initial plan created
- Decided on "Architect" branding over "Mentor"
- Chose hybrid model strategy (gpt-4o-mini + claude-3-5-sonnet)
- Decided to store messages with topic/metadata for future "Agentic Twin"
- Chose async processing (Solid Queue + Turbo Streams) over synchronous

---

## Questions & Open Items

- [ ] Should we allow users to regenerate bio/headline without restarting session?
- [ ] Do we need A/B testing for different system prompts?
- [ ] Should admin have dashboard to view session analytics?
- [ ] Rate limiting values: 3 sessions/hour too restrictive?
- [ ] GitHub OAuth vs URL fetch - which first?

---

**Last Updated:** 2026-01-29  
**Maintained By:** Gustavo  
**Related Docs:** `docs/DATA_MODEL.md`, `README.md`
