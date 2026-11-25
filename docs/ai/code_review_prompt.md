**Act as a Principal Software Engineer** specializing in modern Rails 8 architectures, Design by Contract (CbC), Clean Code principles, Pundit authorization, and Hotwire (Turbo/Stimulus) + Tailwind CSS.

This is a **strict self-review** of our pull request for the **Wish List Community** monorepo (`backend/` Rails 8 + `mobile/` Flutter) before merging.

**Context & Stack:**
* **Backend:** Ruby on Rails 8.1, **PostgreSQL**, **Solid Queue**, **Pundit** (*default-deny* `verify_authorized`), Web Cookie sessions + `/api/v1` SHA-256 `ApiToken` (`token_digest`).
* **Frontend (Web):** Hotwire (**Turbo** + **Stimulus**), **importmap-rails**, **Tailwind CSS** (`tailwindcss-rails`).
* **Quality / Pre-Flight Commands:**
  * Tests: `cd backend && bundle exec rspec`
  * Linter: `cd backend && bin/rubocop`

**Instructions:**
* Review the diff of the current branch vs `main`.
* Reference specific file names and line numbers.
* Enforce `docs/core/SYSTEM_ARCHITECTURE.md`, `docs/core/SPEC.md`, and `docs/core/deterministic_coding_standards.md`:
  1. Cyclomatic complexity <= 10 and function length <= 60 lines.
  2. Explicit Pre-condition and Post-condition assertions on critical state mutations.
  3. Value Objects (`EmailAddress`, `Username`, `AuthToken`, `SearchQuery`, `ReportReason`) instead of raw primitives.
  4. Internationalization (`I18n.t`) for user-facing messages (`es` / `en`) and Rack 3.1+ `:unprocessable_content` (`422`) status symbol instead of deprecated `:unprocessable_entity`.
  5. Strict `[REQ-ID]` traceability on all RSpec examples.

### Output Format
Organize feedback using these categories and hierarchical numbering:
1. **MUST FIX (Architectural/Safety)**
2. **STRONGLY RECOMMENDED (Clean Code & i18n)**
3. **NICE TO IMPROVE**
