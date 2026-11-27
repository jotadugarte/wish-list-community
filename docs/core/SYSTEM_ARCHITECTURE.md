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
* **Mobile Client Surfaces (Flutter thin client):** Auth, social, wishlist, item, reservation/gift, and notification screens live under `mobile/lib/features/` and consume `/api/v1` only — `LoginScreen`, `SignUpScreen`, `PasswordResetScreen`, `AccountRestoreScreen`, `ProfileSettingsScreen` (inbox + prefs + Terms/Privacy links), `FriendsListScreen`, `UserSearchScreen`, `MyWishlistsScreen`, `SharedWishlistsScreen`, `FriendWishlistsScreen`, `WishlistDetailScreen`, `ItemFormScreen` (paste-URL preview + gallery/camera multipart with client compress), `InboxScreen`, `NotificationPrefsScreen`, plus bilingual `AppStrings` (`es` / `en`). Share-to-App uses `SharePayload` / `ShareIntentCoordinator` / `LastWishlistMemory` (device-local); deep links use `DeepLinkTarget` / `DeepLinkRouter` (friend profile + secret link only; activity deferred). FCM via `PushRegistration` (graceful without Google keys). Visual identity is centralized in `DesignTokens` / `AppTheme` / `AppNavigationShell`.
* **Member Hotwire Surfaces (cookie session):** Logged-in shell under `/app` mirrors phone sections (wishlists, shared, friends, reservations, notifications, settings) with server-authority controllers/views. Public bilingual `/terms` and `/privacy` (placeholder copy until owner legal approval). Admin remains `/admin` web-only.
* **App Links association:** Staging host configurable (`PUBLIC_WEB_HOST` / `staging.wishlist.local`); `.well-known/assetlinks.json` and `apple-app-site-association` stubs under `backend/public/` — swap host + signing fingerprints before store submit.

## 2. Architectural Paradigm
* **Server-First Authority:** 100% of business logic, authorization policies, privacy rules, reservation concurrency, and budget validations reside on the Rails 8 server. Both the Web UI and Flutter mobile apps act strictly as clients.
* **Dual Authentication Boundary:**
  * **Web Client:** Stateful Rails 8 cookie sessions (`HttpOnly`, `Secure`, `SameSite=Lax`, CSRF-protected).
  * **Mobile Client (`/api/v1`):** Dedicated `api_tokens` table storing only the **SHA-256 `token_digest`** (never raw tokens in PostgreSQL), with `expires_at`, `revoked_at`, `last_used_at`, `device_name`, and coupled FCM `device_tokens` cleanup on logout/revocation. Flutter persists the raw bearer token in secure storage, sends `Authorization: Bearer`, and maps `401` / `404` / `409` / `422` deterministically; password reset and 30-day account restore are unauthenticated client flows against `POST /api/v1/passwords` and `POST /api/v1/account/restore`.
* **Design Pattern:** Explicit Domain Value Objects, Service Objects for multi-model transactions (reservations, gift fulfillment, Secret Santa Hamiltonian draw, soft-delete cascades), and Pundit Policies for access control.
* **Bounded Hook Registries for Cross-Sprint Cascades:** Cross-module side effects (such as destroying friendships/shares/reservations on `UserBlock.block!` or canceling active reservations on `SoftDeletable#soft_delete!`) use bounded class-level callback registries (`register_cleanup_hook` with `MAX_CLEANUP_HOOKS = 20`, `register_soft_delete_hook` / `register_restore_hook` with `MAX_LIFECYCLE_HOOKS = 20`) executed inside the model's database transaction. Before iterating `@cleanup_hooks`, the dispatcher (`UserBlock.execute_cleanup_hooks!`) must explicitly reference dependent model constants (e.g., `Friendship`) so Zeitwerk autoloads them and registers their hooks even in partial test runs or freshly booted workers.
* **API v1 Locale Propagation Across Exception Handlers:** Set `I18n.locale` in `Api::V1::BaseController` via `before_action :set_user_locale` rather than `around_action :with_user_locale`, because Rails `rescue_from` handlers (`ActiveRecord::RecordNotFound`, `Pundit::NotAuthorizedError`, `ActiveRecord::RecordNotUnique`) execute after an `around_action` unwinds and must preserve the authenticated user's `locale`.
* **Web Hotwire Locale Parity:** Controllers that include cookie-session `WebAuthentication` must set `I18n.locale` from the signed-in user's `locale` (guests keep `I18n.default_locale`) so Secret Link / login / signup HTML matches the bilingual product rule.
* **Soft-Delete Cascade Identity:** When a parent soft-delete cascades child soft-deletes that must later reverse with the parent restore, record the cascaded child IDs on the parent's soft-delete `AuditEvent` metadata and restore only that ID set — never infer children from a time window around `discarded_at`.
* **Viewer-Aware Sensitive Fields:** Capability secrets such as share/invite tokens must be omitted from API serializers unless the viewer is the resource owner (pass an explicit `viewer:` into serializers). Zero-spoiler counterparty identity (gifter or reserver ids) must likewise be omitted from owner-facing payloads unless the viewer is that party or an admin — never serialize those fields unconditionally.
* **Pundit `verify_authorized` on Early Parameter Validation Rescues:** When a controller action validates or resolves parameters before calling `authorize` and rescues `ArgumentError` / `ActiveRecord::RecordInvalid` to render `422 Unprocessable Content`, it must either call `authorize` first or invoke `skip_authorization` inside the `rescue` block so `after_action :verify_authorized` does not raise `Pundit::AuthorizationNotPerformedError`.
* **Batched Relationship Serialization (Zero `N+1` in Bounded Lists):** List and search endpoints (such as `GET /api/v1/users/search`) must batch-load viewer-relative relationship state in a single query (`Friendship.statuses_for(viewer, target_users)`) rather than issuing per-row queries inside JSON serializers. Item list endpoints and Hotwire Secret Link authenticated shells must likewise batch-load active holds, open gifts, and pending-confirm gifts for the page of items (bounded maps) instead of querying per row in serializers or views.
* **Database Concurrency & Idempotency:**
  * Single active reservation per item enforced at the PostgreSQL level via partial unique index (`WHERE status IN ('active', 'expired_grace')`).
  * Unordered unique pair index on friendships (`LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)`).
  * Base controllers gracefully trap `ActiveRecord::RecordNotUnique` and return deterministic `409 Conflict` / idempotent responses.
* **Rails 8 `rate_limit` Naming:** When a controller declares more than one `rate_limit`, each declaration MUST include a distinct `name:` so the cache buckets do not share a key (unnamed dual limits silently throttle unrelated actions).
* **Hotwire Rate-Limit Redirect Status:** Cookie-session mutation `rate_limit` `with:` callbacks that redirect MUST use a 3xx status (`:see_other`) with the wait flash — never `:too_many_requests` on a redirect — so Turbo follows and the user sees the wait copy. JSON `/api/v1` may still render `429`.
* **Authenticated Mutation Rate-Limit Keying:** Authenticated write `rate_limit` declarations MUST key `by:` the current user id with IP only as fallback (`current_user&.id || request.remote_ip`), not IP alone (shared NAT false-throttles; IP rotation bypasses per-account caps).
* **Client Mapping of Validation Errors:** Clients MUST NOT map every HTTP `422` to a single user-facing string when the API distinguishes cases (for example duplicate pending vs invalid payload). Prefer the server error body / dedicated copy per case.

## 3. The "Kill List" (Forbidden Patterns)
*AI Agents MUST NOT use or suggest the following under any circumstances:*
* **Plain-Text API Tokens in DB:** Never store raw bearer tokens in PostgreSQL; only SHA-256 digests (`token_digest`) are permitted.
* **Client-Side Permission Checks as Security:** Never rely on Flutter or frontend conditionals to enforce blocking, friendship visibility, or reservation ownership.
* **Heavy Frontend SPA Frameworks in Web:** No React, Vue, Angular, or custom Webpack/Vite bundles inside `backend/`; use Hotwire (Turbo + Stimulus) via `importmap`.
* **Side-Channel Timestamp Leaks on Items:** Reserving or marking an item as secretly purchased MUST NOT update `items.updated_at` or expose reservation fields or gifter identity in owner-facing serializers.
* **Public Stalking / Unsolicited Profile Exposure:** Searching a `@username` must never expose a user's personal wishlists to non-friends, and email addresses must never be serialized in public or friend responses.
* **Retaining EXIF/GPS Metadata on Uploads:** Never persist user-uploaded images without stripping EXIF/GPS metadata via `libvips`.
* **Fat Controllers:** Controllers must remain thin (routing, parameter extraction, Pundit authorization, and delegating to domain models or service objects).

## 4. Environment & Infrastructure
* **Deployment Target:** Rails 8 (`backend/`) via Docker/Kamal + PostgreSQL; Flutter (`mobile/`) to Apple App Store and Google Play Store.
* **Secrets Management:** Rails Encrypted Credentials / Environment Variables.
* **Internationalization & Timezones:** Built-in `I18n` (`es` / `en`) and per-user `time_zone` stored on `users` from Sprint 1.
