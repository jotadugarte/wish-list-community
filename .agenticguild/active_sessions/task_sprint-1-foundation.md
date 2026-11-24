<task_session>
  <metadata>
    <task_name>Holistic Project Architecture & MVP Sprint 1 Discovery</task_name>
    <type>Feature</type>
    <req_id>REQ-ARCH-001, REQ-AUTH-001, REQ-USER-001, REQ-BLOCK-001, REQ-LIFE-001, REQ-SOC-001, REQ-WISH-001, REQ-ITEM-001, REQ-RES-001, REQ-GIFT-001, REQ-DISC-001, REQ-ADM-001, REQ-NOTIF-001</req_id>
    <roadmap_item>Full Project Architecture Review + MVP Sprints 1–9</roadmap_item>
  </metadata>

  <working_notes>
## Confirmed Architectural Decisions
- **Repository Structure**: Monorepo (`backend/` for Ruby on Rails 8 + PostgreSQL + Hotwire, `mobile/` for Flutter iOS/Android).
- **Backend & Web Stack**:
  - Ruby on Rails 8 + PostgreSQL + Solid Queue
  - Hotwire (Turbo Drive, Turbo Frames, Turbo Streams + Stimulus) via `importmap-rails`
  - **UI / Styling**: Tailwind CSS (`tailwindcss-rails`) for minimal CSS payload and fastest rendering response
  - **Authorization**: **Pundit** with strict `verify_authorized` and `verify_policy_scoped` default-deny enforcement
  - **Testing**: **RSpec** + FactoryBot
- **Authentication & API Security**:
  - Web: Native Rails 8 cookie sessions (`HttpOnly`, `Secure`, `SameSite=Lax`, CSRF protection)
  - Mobile (`/api/v1`): Dedicated `api_tokens` table storing only **SHA-256 `token_digest`** (never plain-text tokens), with `expires_at`, `revoked_at`, `last_used_at`, and `device_name`.
- **Username Cooldown (`REQ-USER-001`)**: 30 days between username changes.
- **Soft-Delete & Ghost Reservations (`REQ-LIFE-001`)**:
  - Soft-deleting a `Wishlist` or `Item` immediately cancels active/expired reservations (`canceled_by_deletion`).
  - Restoring a `Wishlist` restores its items clean, without resurrecting old reservations ("no ghost reservations").
- **Block vs. Friendship & Reservations (`REQ-BLOCK-002`)**:
  - Blocking a user permanently destroys any friendship/pending request between them, removes `WishlistShare` records, and silently cancels any active reservations either user holds on the other's items.
- **Secret Link Permissions (`REQ-WISH-002`)**:
  - **Option A Confirmed**: Any logged-in, non-blocked user who accesses a `shared` wishlist via a valid `share_token` (Secret Link) can both **view** and **reserve/gift** items on that wishlist, even if they are not on the owner's friends list.
  - Switching a wishlist to `private` immediately wipes/invalidates `share_token`.
- **Image Processing & Privacy (`REQ-ITEM-002`)**:
  - Rails 8 `ActiveStorage` + `libvips` transcodes images to WebP (<=1600px, <=2MB, max 3) and **strips all EXIF/GPS metadata** on upload.
  - Item links validate strict `http://` or `https://` schemes.
- **Reservation & Gifted Privacy (`REQ-RES-002`, `REQ-GIFT-002`)**:
  - Reservations never touch `items.updated_at` (no timing side-channel leaks).
  - Other viewers with access only see anonymous reservation/gifted status; only the reserver and Admin know who reserved.
  - **Option A Confirmed (Surprise Protection on Gifted)**: When a gifter marks an item as `"gifted"`, it remains **hidden from the wishlist owner** (only other friends/viewers see it is already gifted so nobody buys a duplicate). The owner only sees an item as received/gifted when the owner themselves marks it as received (or if revealed).
- **Discover Feed Hygiene (`REQ-DISC-002`)**:
  - Public wishlists with **0 active items** are excluded from the public Discover feed.
- **Admin Audit Trail Foundation (`REQ-ADM-001`)**:
  - Immutable `audit_events` table (`actor_id`, `action`, `auditable_type`, `auditable_id`, `metadata_jsonb`) included from the start to support Sprint 8 inspection and revert.
- **Future-Proofing for v1 Activities (`REQ-ARCH-002`)**:
  - `items` table includes nullable `price_cents` (integer) and `currency` (string); `wishlists` is designed to optionally link to an `activity_id` in v1.
- **Notifications on Owner Edit/Delete of Reserved or Gifted Items (`REQ-RES-003`)**:
  - Deleting an item with an active reservation (or marked gifted by a friend) immediately notifies that friend.
  - Editing critical fields (`title`, `notes`, `links`) of an item with an active reservation notifies the reserver.
- **Dual-Path Gift Fulfillment Lifecycle (`REQ-GIFT-003`)**:
  - Supports both paths seamlessly:
    1. **Gifter-initiated**:
       - `purchased_secret`: Gifter marks item as bought/gifted before delivery -> hidden from owner (preserves surprise), visible to other friends as *"Already gifted"*, cancels active reservations.
       - `delivered_pending_confirmation`: Gifter marks *"Already delivered"* -> notifies owner anonymously (*"Someone marked [Item] as delivered! Confirm receipt?"*) -> owner confirms in 1 tap (`received_confirmed`).
    2. **Owner 1-step confirmation**:
       - Owner can directly mark any item as *"Received"* (`received_confirmed`) in a single step at any time (canceling any active reservation and notifying the reserver/gifter).
- **"My Reservations" & Persistent Secret-Link Access (`REQ-RES-004`, `REQ-WISH-003`)**:
  - Dedicated `"My Reservations"` view/endpoint (`/api/v1/my_reservations`) for active reservations across all wishlists.
  - Opening a valid Secret Link while logged in automatically registers access in `"Shared with me"` (`WishlistShare` with `source: 'secret_link'`) while the token remains valid and unblocked.
- **Anti-Hoarding Per-Wishlist Reservation Limit (`REQ-RES-005`)**:
  - Maximum **3 active reservations simultaneously per user within the same wishlist** (no global limit across wishlists).
- **Item Priority / Desire Levels (`REQ-ITEM-003`)**:
  - Items include a `priority` enum (`low`, `medium`, `high`, `must_have`) so owners can highlight what they want most.
- **App Store & Google Play Compliance (`REQ-LIFE-002`, `REQ-AUTH-002`)**:
  - In-app account soft-delete has a **30-day restore grace period** on login, after which a Solid Queue job permanently purges/anonymizes PII.
  - Users accept UGC Terms/EULA (`terms_accepted_at`) at sign-up.
- **URL Metadata OpenGraph Preview**:
  - Deferred to Backlog (keep MVP Sprint 4 manual entry for reliability).
- **Optional `event_date` on Wishlists (`REQ-WISH-004`)**:
  - Wishlists include an optional `event_date` (Date) so friends see the target date and reservations warn if `estimated_date > event_date`.
- **Visual Separation of Received Items (`REQ-ITEM-004`)**:
  - Items in `received_confirmed` state move to a separated/collapsed *"Received Gifts"* section at the bottom of the wishlist.
- **1 Item = 1 Giftable Unit in MVP (`REQ-ITEM-005`)**:
  - Each item record represents 1 unit in MVP, keeping the PostgreSQL partial unique index on active reservations 100% deterministic.
- **User Preferred `locale` (`es` / `en`) from Sprint 1 (`REQ-USER-002`)**:
  - Stored on `users` table so asynchronous emails and push notifications via Solid Queue are localized.
- **Safe OpenGraph Previews & Post-Login `return_to` for Secret Links (`REQ-WISH-005`)**:
  - Unauthenticated requests to a valid Secret Link receive safe OpenGraph invitation metadata (*"Wishlist by @username"*) without leaking private item data, and preserve `return_to` across login/sign-up.
- **Timezone-Safe Reservation Expiration (`REQ-USER-003`, `REQ-RES-006`)**:
  - Store `time_zone` on `users` (default `UTC`) and only expire a reservation once `estimated_date` has fully elapsed in the reserver's timezone.
- **Secret Santa (`v1 Sprint A — Activities`) Draw Guards & Exclusions (`REQ-ACT-001`)**:
  - Require minimum **3 `accepted` participants** to run the draw.
  - Include **Draw Exclusions (`ActivityExclusion`: Participant A cannot draw Participant B)** directly in **v1 Sprint A** (not Backlog), with deterministic graph solvability validation before committing the draw.
- **Anonymous "Thank You" Note on Confirmed Gift Receipt (`REQ-GIFT-004`)**:
  - When the owner confirms an item as received (`received_confirmed`), they can attach an optional thank-you message delivered privately to the actual gifter without revealing the gifter's identity to the owner.
- **Native Mobile "Share to App" Sheet in MVP Sprint 9 (`REQ-MOB-001`)**:
  - Include OS Share Sheet extension (iOS & Android in Flutter) directly in **MVP Sprint 9** (not Backlog) so users can share product links from Amazon/MercadoLibre directly into *"Add Item to Wishlist"*.
- **Smart Parsing of Shared Text in Mobile "Share to App" (`REQ-MOB-002`)**:
  - Automatically extract `https://` URLs from mixed shared store text into the item link field and pre-fill the remaining cleaned text as the suggested item title, with a wishlist selector.
- **Push Notification `device_token` Unbinding on Logout / Revocation (`REQ-NOTIF-002`)**:
  - Bind FCM `device_tokens` to the active `api_token_id` and automatically delete/deactivate the device token on logout (`DELETE /api/v1/session`) or token revocation to prevent push notification spoilers on shared devices.
- **Deterministic Solvability Validation on Secret Santa Exclusions (`REQ-ACT-002`)**:
  - Validate exclusion graphs with a bounded deterministic bipartite matching check before executing a `secret_santa` draw; return an actionable error if constraints make a valid draw mathematically impossible.
- **Blind Participant Dropout Recovery After Secret Santa Draw (`REQ-ACT-003`)**:
  - If a participant drops out or is removed after the draw, the creator chooses between **(A) Blind Auto-Bridge (`A -> C`)** or **(B) Full Redraw**.
  - **Strict Privacy Invariant**: During Blind Auto-Bridge, the server executes the reassignment and notifies the affected gifter privately **without ever revealing to the activity creator who gifts whom**.
- **Anti-Enumeration on Auth & Sprint 1 Rate-Limiting (`REQ-AUTH-003`)**:
  - Password reset always returns a generic `200 OK` message without revealing whether an email exists.
  - Rails 8 native `rate_limit` protects `/login`, `/signup`, and `/passwords` starting in Sprint 1.
- **Discover Users Privacy vs. `@username` Search (`REQ-DISC-003`)**:
  - Any active non-blocked user can be found via `@username` search to send friend requests, whereas the public **Discover Users** feed only lists users who have at least 1 `public` wishlist containing >= 1 active item.
- **Database Idempotency & `RecordNotUnique` Handling (`REQ-ARCH-003`)**:
  - Base API/Web controllers gracefully handle `ActiveRecord::RecordNotUnique` on double-taps, returning deterministic `409 Conflict` / idempotent responses instead of `500` errors.
- **Single-Cycle Draw & Exclusion Check on Blind Auto-Bridge (`REQ-ACT-004`)**:
  - Initial Secret Santa draw always generates a single Hamiltonian cycle (no 2-person `A <-> B` sub-loops when >= 3 participants exist).
  - If bridging `A -> C` on dropout violates an `ActivityExclusion` or leaves < 3 participants, the system alerts the creator (without revealing names) that a full redraw is required.
- **Immutable Wishlist URLs & 30-Day Old-Username Quarantine (`REQ-USER-004`, `REQ-WISH-006`)**:
  - Wishlist and Secret Link URLs use immutable wishlist identifiers (`/wishlists/:id` and `/s/:share_token`) independent of `@username`.
  - Previous usernames are quarantined for 30 days upon change to prevent impersonation.
- **Backlog Addition — Group Co-Gifting ("Cooperacha")**:
  - Added to Backlog v1 so multiple friends can optionally chip in on a single expensive item reservation in the future.

## Phase 8 Discovery: Co-Founder Review Feedback from Ceci Pinilla ("Ñata") — APPROVED IN ROUND 2 (5/5 Approved — "Todo cool!")
*Sources: `docs/references/revision_diseno_nata_completada.html` (Round 1) & `docs/references/revision_onda_2_nata_completada.html` (Round 2: 5/5 Approved)*

1. **Ajuste 01 (Bloques 04 & 09) — Anti-Stalking Privacy & Complete Visibility Scenario Matrix (`REQ-WISH-001`, `REQ-DISC-001` — APPROVED)**:
   - Searching a user's `@username` NEVER exposes their personal wishlists to strangers (only shows `@username` and *"Send Friend Request"*). No public stalking catalog of personal wishlists.
   - Personal wishlists are accessible only to **accepted friends** (`friends`) or **selected friends + explicit Secret Link** (`shared`).
   - Group Activity links can be shared with external guests outside the app, exposing **exclusively** the information and items of that specific activity without exposing personal profiles or other lists.
2. **Ajuste 02 (Bloque 05) — Automatic Store Image/Title Extraction in MVP + Specification Notes (`REQ-ITEM-006` — APPROVED)**:
   - Promoted **Automatic Store Image & Title Extraction (`og:image`, `og:title`)** from Backlog into **MVP (Sprint 4 / Sprint 9)** when pasting or sharing a link from Amazon/MercadoLibre/stores (with manual upload of up to 3 photos also supported).
   - Dedicated, prominent **`specifications` / variant note** field right below the item photo so the owner can clarify exact color/size/model when the store's default preview image shows a different variant.
3. **Ajuste 03 (Bloque 06) — 72-Hour Auto-Release Grace Window on Expired Reservations & Context-Aware Reservation Limits (`REQ-RES-005`, `REQ-RES-006` — APPROVED)**:
   - **72-Hour Auto-Release**: When `estimated_date` expires, notify the reserver and grant a **72-hour (3-day) grace window** to extend (with max extension cap) or mark as purchased; if ignored after 72 hours, **automatically release** the reservation so the item is never stuck for years.
   - **Context-Aware Reservation Limits**: Personal wishlists default to **no per-person cap** (or owner-configurable limit) so partners/family can reserve multiple gifts in Christmas/Birthdays; Group Activities (`secret_santa`) default to **1 active reservation per participant** (or organizer-configured limit).
4. **Ajuste 04 (Bloque 07) — Unified "Reserved / Unavailable" Status for Other Friends & Strict Reserver Ownership (`REQ-GIFT-002`, `REQ-GIFT-003` — APPROVED)**:
   - While an item is reserved or purchased in secret, all other friends simply see a single unified state: **`"Reserved / Unavailable"`** (no need to expose `"Gifted"` to third parties before delivery).
   - **No Third-Party Conflict**: Another friend cannot mark an already-reserved item as gifted or override someone else's active reservation. Only the active reserver can mark it purchased/delivered, OR the **wishlist owner** can mark *"I already received this"* (e.g., gifted offline), which cancels the reservation and notifies the reserver.
5. **Ajuste 05 (Bloque 08) — 5 Flexible Budget Modes in Group Activities (`REQ-ACT-005` — APPROVED)**:
   - When creating a Group Activity, the organizer chooses from 5 budget rules (`budget_mode`): `fixed` (exact amount), `min_only` (minimum), `max_only` (maximum), `range` (min and max), or `none` (unrestricted).

## Domain Model (Project-Wide Overview)

### 1. `User` (Sprint 1 — Approved Value Objects)
- **Responsibility**: Identity, auth credentials, public profile (`username`), role (`user` / `admin`), localization (`locale`, `time_zone`), terms compliance (`terms_accepted_at`), and soft-delete lifecycle (`discarded_at`).
- **Invariants**:
  - `email_address` is private and never serialized in public/friend endpoints.
  - `username` is unique (case-insensitive), subject to a 30-day change cooldown (`username_changed_at`), and old usernames enter a 30-day quarantine (`UsernameReservation`) upon change.
- **Approved Value Objects (Step 3.0 Gate — Confirmed)**:
  - `EmailAddress`: Wraps String; normalizes (`strip.downcase`) and validates strict email format (`REQ-USER-001`, `REQ-AUTH-001`).
  - `Username`: Wraps String; normalizes lowercase, enforces `3..30` length, `/\A[a-z0-9_]+\z/` format, and rejects system reserved words (`REQ-USER-001`, `REQ-USER-004`).
  - `AuthToken`: Wraps raw token generation (`SecureRandom.base58(32)`) and deterministic SHA-256 `token_digest` calculation (`REQ-AUTH-001`).

### 2. `UserBlock` & `Friendship` (Sprints 1–2)
- **Responsibility**: Directional blocks (`blocker_id`, `blocked_id`) and bidirectional friendships (`requester_id`, `addressee_id`, `status`).
- **Invariants**:
  - **Block Wins**: Any block in either direction permanently destroys existing friendships/shares, silently cancels active reservations between the two users, and overrides all access.
  - Unique unordered pair index on `friendships` (`LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)`) prevents duplicate inverse friend requests.

### 3. `Wishlist` & `WishlistShare` (Sprint 3)
- **Responsibility**: Container of desired items with anti-stalking privacy (`friends` for all accepted friends, `shared` for specific friends + optional `share_token` Secret Link), optional `event_date`, and configurable `max_reservations_per_user` (nullable/unlimited by default for personal wishlists).
- **Invariants**:
  - Strangers searching `@username` never see personal wishlists.
  - Switching a `shared` wishlist to private friends-only immediately invalidates `share_token`.
  - Soft-deleting a `Wishlist` cascades soft-delete to its `Items` and permanently cancels active `Reservations` (no ghost reservations on restore).

### 4. `Item` & `ItemLink` (Sprint 4)
- **Responsibility**: A single giftable unit inside a `Wishlist`, with `priority` (`low`, `medium`, `high`, `must_have`), prominent `specifications` note (exact color/size/variant clarification), nullable `price_cents`/`currency` (for v1 Activities), multiple external purchase URLs (`ItemLink`), automatic store image/title extraction (`og:image`, `og:title`), and up to 3 processed WebP images.
- **Invariants**:
  - Max 3 images per item; each <= 2MB and <= 1600px longest side; all EXIF/GPS stripped via `libvips`.
  - Reservation/Gift mutations must never touch `Item#updated_at` (prevents timing side-channel leaks to the item owner).
- **Value Objects**: `ExternalUrl` (strict `http/https` validation + SSRF-safe metadata preview), `ImageDimensions`.

### 5. `Reservation` & `GiftRecord` (Sprints 5–6)
- **Responsibility**: Tracks item reservations (`active`, `expired_grace`, `auto_released`, `canceled`, `completed_by_gift`) with a 72-hour auto-release grace window after `estimated_date`, and dual-path gift fulfillment (`purchased_secret`, `delivered_pending_confirmation`, `received_confirmed`) with optional anonymous thank-you note.
- **Invariants**:
  - Enforced by PostgreSQL partial unique index: `CREATE UNIQUE INDEX idx_unique_active_reservation ON reservations (item_id) WHERE status IN ('active', 'expired_grace')`.
  - Other friends only see unified `"Reserved / Unavailable"` status; third parties cannot override another friend's active reservation (only the reserver or the wishlist owner confirming receipt can complete/close it).
  - Invisible to the wishlist owner until `delivered_pending_confirmation` or `received_confirmed`.

### 6. `Activity`, `ActivityParticipant` & `ActivityExclusion` (v1 Sprints A–B)
- **Responsibility**: Group gifting (`secret_santa` 1->1 single Hamiltonian cycle draw or `open_gifting`), external activity link access (scoped strictly to that activity's info), 5 budget modes (`none`, `fixed`, `min_only`, `max_only`, `range`), default 1 reservation limit per participant in Secret Santa, pair exclusions, and blind dropout bridging.

### 7. `Report`, `AuditEvent`, `NotificationPreference` & `DeviceToken` (Sprints 2, 7, 8 & Notifications)
- **Responsibility**: Abuse reporting (`Report` polymorphic on `User`/`Wishlist`), immutable admin audit trail (`AuditEvent`), localized notifications (`in_app`, `email`, `push`), and `api_token`-bound `DeviceToken` (auto-unbound on logout).
  </working_notes>

  <implementation_plan>
    <step id="1" status="done">Synchronize all project governance and architecture anchor documents (`docs/ROADMAP.md`, `docs/core/SYSTEM_ARCHITECTURE.md`, `docs/core/SPEC.md`, `docs/core/DATA_FLOW_MAP.md`, `docs/core/TESTING_STRATEGY_MATRIX.md`, `.cursorrules`, and `.agents/rules/agentic-guild.md`) with our complete holistic architecture, domain glossary, business rules, and `[REQ-ID]` traceability codes.</step>
    <step id="2" status="complete">Bootstrap the monorepo foundation (`backend/` with Ruby on Rails 8 + PostgreSQL + Solid Queue + Hotwire/Tailwind CSS + RSpec + Pundit, and `mobile/` directory structure for Flutter) and run a smoke test to verify a green test runner baseline.</step>
    <step id="3" status="pending">Write failing RSpec unit and model specs (`[REQ-USER-001]`, `[REQ-USER-002]`, `[REQ-USER-003]`, `[REQ-USER-004]`, `[REQ-AUTH-002]`) for `User` (private normalized email, unique `@username`, 30-day username change cooldown + 30-day old-username quarantine, `locale`, `time_zone`, `terms_accepted_at`), then implement `User`, value objects (`EmailAddress`, `Username`), and migrations to make the tests pass.</step>
    <step id="4" status="pending">Write failing RSpec request and model specs (`[REQ-AUTH-001]`, `[REQ-AUTH-003]`, `[REQ-NOTIF-002]`) for Web Cookie Sessions and `/api/v1` Token Authentication (`ApiToken` with SHA-256 `token_digest`, expiration, revocation, `device_token` unbinding on logout, generic `200 OK` password reset anti-enumeration, and Rails 8 `rate_limit`), then implement the controllers and authentication services to make the tests pass.</step>
    <step id="5" status="pending">Write failing RSpec policy and model specs (`[REQ-BLOCK-001]`, `[REQ-BLOCK-002]`, `[REQ-ADM-001]`, `[REQ-ARCH-003]`) for Pundit default-deny authorization, `UserBlock` ("block wins" invariant + cascading cleanup hooks), immutable `AuditEvent` logging, and `RecordNotUnique` idempotency handling, then implement `ApplicationPolicy`, `UserBlock`, and `AuditEvent` to make the tests pass.</step>
    <step id="6" status="pending">Write failing RSpec specs (`[REQ-LIFE-001]`, `[REQ-LIFE-002]`) for the `SoftDeletable` concern (soft-delete, 30-day account restoration window, PII purge job contract, and callback hooks preventing ghost reservations upon restoration), then implement `SoftDeletable` and restoration logic to make the tests pass.</step>
  </implementation_plan>
</task_session>
