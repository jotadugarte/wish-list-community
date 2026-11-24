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
* **Testing Suite:** RSpec + FactoryBot (`backend/`), `flutter_test` (`mobile/`)

## 2. Architectural Paradigm
* **Server-First Authority:** 100% of business logic, authorization policies, privacy rules, reservation concurrency, and budget validations reside on the Rails 8 server. Both the Web UI and Flutter mobile apps act strictly as clients.
* **Dual Authentication Boundary:**
  * **Web Client:** Stateful Rails 8 cookie sessions (`HttpOnly`, `Secure`, `SameSite=Lax`, CSRF-protected).
  * **Mobile Client (`/api/v1`):** Dedicated `api_tokens` table storing only the **SHA-256 `token_digest`** (never raw tokens in PostgreSQL), with `expires_at`, `revoked_at`, `last_used_at`, `device_name`, and coupled FCM `device_tokens` cleanup on logout/revocation.
* **Design Pattern:** Explicit Domain Value Objects, Service Objects for multi-model transactions (reservations, gift fulfillment, Secret Santa Hamiltonian draw, soft-delete cascades), and Pundit Policies for access control.
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
