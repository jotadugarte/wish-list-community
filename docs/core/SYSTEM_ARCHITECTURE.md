# System Architecture & Boundaries

**Purpose:** This document defines the unchangeable technical laws of the project. AI agents are strictly forbidden from proposing or implementing solutions that violate these boundaries unless an explicit Architectural Decision Record (ADR) is approved.

## 1. Repository & Technology Stack (Monorepo)
* **Repository Layout:** Monorepo at root (`/`)
  * `backend/` — Ruby on Rails 8 application (Server-Rendered Web + `/api/v1` REST API + Web-only Admin Panel)
  * `mobile/` — Flutter application (iOS & Android native clients consuming `/api/v1`)
  * `docs/` & `.agenticguild/` — Shared architectural governance, specifications, and persistent task memory
* **Backend Language/Runtime:** Ruby 3.3+
* **Core Backend Framework:** Ruby on Rails 8
* **Primary Database & Queue:** PostgreSQL (with partial unique indexes and functional indexes) + Solid Queue (background jobs & scheduled tasks)
* **Web UI & Styling Engine:** Server-rendered HTML + Hotwire (Turbo Drive, Turbo Frames, Turbo Streams + Stimulus via `importmap-rails`) + Tailwind CSS (`tailwindcss-rails`)
* **Authorization Engine:** Pundit (`ApplicationPolicy` with mandatory `after_action :verify_authorized` and `after_action :verify_policy_scoped` default-deny enforcement)
* **Image Processing:** ActiveStorage + `image_processing` (`libvips`) with mandatory server-side resize (<= 1600px), WebP encoding, and full EXIF/GPS metadata stripping
* **Testing Suite:** RSpec + FactoryBot (`backend/`), `flutter_test` (`mobile/`) with CI job `flutter_test` (`flutter analyze` + `flutter test`)
* **Mobile Client Surfaces (Flutter thin client):** Auth and social screens live under `mobile/lib/features/` and consume `/api/v1` only — `LoginScreen`, `SignUpScreen`, `PasswordResetScreen`, `AccountRestoreScreen`, `ProfileSettingsScreen`, `FriendsListScreen`, `UserSearchScreen`, plus bilingual `AppStrings` (`es` / `en`). Visual identity is centralized in `DesignTokens` / `AppTheme` / `AppNavigationShell`.

## 2. Architectural Paradigm
* **Server-First Authority:** 100% of business logic, authorization policies, privacy rules, reservation concurrency, and budget validations reside on the Rails 8 server. Both the Web UI and Flutter mobile apps act strictly as clients.
* **Dual Authentication Boundary:**
  * **Web Client:** Stateful Rails 8 cookie sessions (`HttpOnly`, `Secure`, `SameSite=Lax`, CSRF-protected).
  * **Mobile Client (`/api/v1`):** Dedicated `api_tokens` table storing only the **SHA-256 `token_digest`** (never raw tokens in PostgreSQL), with `expires_at`, `revoked_at`, `last_used_at`, `device_name`, and coupled FCM `device_tokens` cleanup on logout/revocation. Flutter persists the raw bearer token in secure storage, sends `Authorization: Bearer`, and maps `401` / `404` / `409` / `422` deterministically; password reset and 30-day account restore are unauthenticated client flows against `POST /api/v1/passwords` and `POST /api/v1/account/restore`.
* **Design Pattern:** Explicit Domain Value Objects, Service Objects for multi-model transactions (reservations, gift fulfillment, Secret Santa Hamiltonian draw, soft-delete cascades), and Pundit Policies for access control.
* **Bounded Hook Registries for Cross-Sprint Cascades:** Cross-module side effects (such as destroying friendships/shares/reservations on `UserBlock.block!` or canceling active reservations on `SoftDeletable#soft_delete!`) use bounded class-level callback registries (`register_cleanup_hook` with `MAX_CLEANUP_HOOKS = 20`, `register_soft_delete_hook` / `register_restore_hook` with `MAX_LIFECYCLE_HOOKS = 20`) executed inside the model's database transaction. Before iterating `@cleanup_hooks`, the dispatcher (`UserBlock.execute_cleanup_hooks!`) must explicitly reference dependent model constants (e.g., `Friendship`) so Zeitwerk autoloads them and registers their hooks even in partial test runs or freshly booted workers.
* **API v1 Locale Propagation Across Exception Handlers:** Set `I18n.locale` in `Api::V1::BaseController` via `before_action :set_user_locale` rather than `around_action :with_user_locale`, because Rails `rescue_from` handlers (`ActiveRecord::RecordNotFound`, `Pundit::NotAuthorizedError`, `ActiveRecord::RecordNotUnique`) execute after an `around_action` unwinds and must preserve the authenticated user's `locale`.
* **Pundit `verify_authorized` on Early Parameter Validation Rescues:** When a controller action validates or resolves parameters before calling `authorize` and rescues `ArgumentError` / `ActiveRecord::RecordInvalid` to render `422 Unprocessable Content`, it must either call `authorize` first or invoke `skip_authorization` inside the `rescue` block so `after_action :verify_authorized` does not raise `Pundit::AuthorizationNotPerformedError`.
* **Batched Relationship Serialization (Zero `N+1` in Bounded Lists):** List and search endpoints (such as `GET /api/v1/users/search`) must batch-load viewer-relative relationship state in a single query (`Friendship.statuses_for(viewer, target_users)`) rather than issuing per-row queries inside JSON serializers.
* **Database Concurrency & Idempotency:**
  * Single active reservation per item enforced at the PostgreSQL level via partial unique index (`WHERE status IN ('active', 'expired_grace')`).
  * Unordered unique pair index on friendships (`LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)`).
  * Base controllers gracefully trap `ActiveRecord::RecordNotUnique` and return deterministic `409 Conflict` / idempotent responses.

## 3. The "Kill List" (Forbidden Patterns)
*AI Agents MUST NOT use or suggest the following under any circumstances:*
* **Plain-Text API Tokens in DB:** Never store raw bearer tokens in PostgreSQL; only SHA-256 digests (`token_digest`) are permitted.
* **Client-Side Permission Checks as Security:** Never rely on Flutter or frontend conditionals to enforce blocking, friendship visibility, or reservation ownership.
* **Heavy Frontend SPA Frameworks in Web:** No React, Vue, Angular, or custom Webpack/Vite bundles inside `backend/`; use Hotwire (Turbo + Stimulus) via `importmap`.
* **Side-Channel Timestamp Leaks on Items:** Reserving or marking an item as secretly purchased MUST NOT update `items.updated_at` or expose reservation fields in owner-facing serializers.
* **Public Stalking / Unsolicited Profile Exposure:** Searching a `@username` must never expose a user's personal wishlists to non-friends, and email addresses must never be serialized in public or friend responses.
* **Retaining EXIF/GPS Metadata on Uploads:** Never persist user-uploaded images without stripping EXIF/GPS metadata via `libvips`.
* **Fat Controllers:** Controllers must remain thin (routing, parameter extraction, Pundit authorization, and delegating to domain models or service objects).

## 4. Environment & Infrastructure
* **Deployment Target:** Rails 8 (`backend/`) via Docker/Kamal + PostgreSQL; Flutter (`mobile/`) to Apple App Store and Google Play Store.
* **Secrets Management:** Rails Encrypted Credentials / Environment Variables.
* **Internationalization & Timezones:** Built-in `I18n` (`es` / `en`) and per-user `time_zone` stored on `users` from Sprint 1.
