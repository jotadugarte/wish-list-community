# Project Specification (SPEC.md)

> **REQ-ID format:** `REQ-[DOMAIN]-[NNN]` for strict requirement-to-test traceability across RSpec and Flutter tests.

## 1. Purpose & Vision
**Wish List Community** is a privacy-first social wishlist and group gifting platform (Web + iOS + Android). Users create wishlists, connect with trusted friends, share specific lists or group activities via links, reserve gifts secretly without spoiling the surprise for the recipient, and organize group exchanges (Secret Santa and Open Gifting) with configurable budget rules and mathematical draw guarantees.

---

## 2. Domain Glossary

| Term | Definition | Semantic Meaning in Code |
|------|------------|--------------------------|
| **Block Wins** | Access control law where a block between two users immediately terminates all visibility, friendships, shares, and active reservations in both directions. | Enforced centrally in `ApplicationPolicy` and `UserBlockService` (`REQ-BLOCK-001`, `REQ-BLOCK-002`). |
| **Quarantined Username** | A previously used `@username` locked for 30 days after a user changes their handle so no third party can claim it to impersonate them. | Tracked via `UsernameReservation` / cooldown checks (`REQ-USER-004`). |
| **Ghost Reservation** | An invalid state where a soft-deleted and later restored wishlist/item resurrects an old reservation that the reserver already gave up on. | Prevented by permanently canceling reservations upon item/wishlist soft-delete (`REQ-LIFE-001`). |
| **Expired Grace Window** | A 72-hour (3-day) period after a reservation's `estimated_date` passes during which the reserver is notified and can extend or mark as purchased before automatic release. | `Reservation` status `expired_grace` -> `auto_released` after 72h (`REQ-RES-006`). |
| **Blind Auto-Bridge** | Re-stitching a Secret Santa Hamiltonian cycle (`A -> B -> C` becomes `A -> C`) when `B` drops out after the draw, without revealing to the activity creator who gifts whom. | Executed server-side in `ActivityDropoutBridgeService` (`REQ-ACT-003`, `REQ-ACT-004`). |

---

## 3. Complete Visibility & Anti-Stalking Scenario Matrix (`REQ-WISH-001`, `REQ-DISC-001`)

Personal wishlists are **never** exposed to strangers who merely search or guess a user's `@username`.

| Actor / Scenario | Searching `@username` | Personal Lists (`friends`) | Personal List with Secret Link (`shared`) | Group Activity via Activity Link |
| :--- | :--- | :--- | :--- | :--- |
| **1. Stranger / Non-Friend** (No link) | Sees only `@username` and *"Send Friend Request"* button. | **Zero access.** | **Zero access.** | **Zero access.** |
| **2. Accepted Friend** | Sees friend profile. | **Can view and reserve items.** | Can view/reserve only if explicitly authorized or via Secret Link. | Can view/participate only if invited/joined. |
| **3. External Guest with Secret Link or Activity Link** | Cannot browse user's other personal lists. | **No access to other personal lists.** | Views **only** the specific linked wishlist (must log in to reserve). | Views **only** that specific activity's info and items (must log in to participate/reserve). |
| **4. Blocked User (Either Direction)** | User does not appear in search (`404`). | **Zero access.** | **Zero access** (even if holding the link URL). | **Zero access / Cannot participate.** |

---

## 4. Core Entities, Invariants & Value Objects

### 4.1 `User`, `Session` & `ApiToken`
* **Responsibility:** Identity, authentication credentials, public `@username`, localization (`locale`, `time_zone`), terms compliance (`terms_accepted_at`), and soft-delete lifecycle (`discarded_at`).
* **Invariants:**
  * `email_address` is normalized, unique, and strictly private (never serialized in public or friend payloads).
  * `username` is unique (case-insensitive), URL-safe, subject to a **30-day change cooldown** (`username_changed_at`), and old usernames are quarantined for **30 days** upon change.
  * `ApiToken` persists only `token_digest` (SHA-256), never raw tokens.
  * Soft-deleted users have a **30-day restore grace period** on login, after which a background job permanently purges/anonymizes PII.
* **Value Objects:** `EmailAddress`, `Username`, `AuthToken`.

### 4.2 `UserBlock` & `Friendship`
* **Responsibility:** Directional blocking (`blocker_id`, `blocked_id`) and bidirectional friendships (`requester_id`, `addressee_id`, `status: pending | accepted`).
* **Invariants:**
  * A user cannot block or befriend themselves.
  * Unordered unique pair index on `friendships` (`LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)`) prevents duplicate inverse requests.
  * Maximum **20 pending outgoing friend requests** (`MAX_PENDING_OUTGOING = 20`) per user to prevent spam.
  * Creating a `UserBlock` transactionally destroys any existing `Friendship`, removes `WishlistShare` records, and silently cancels active `Reservations` between the two users.
* **Value Objects:** `SearchQuery` (`2..30` valid handle characters, strips leading `@` and escapes SQL wildcards for prefix searches).

### 4.3 `Wishlist` & `WishlistShare`
* **Responsibility:** Collection of desired items with anti-stalking privacy (`friends` for all accepted friends, `shared` for selected friends + Secret Link `share_token`), optional `event_date`, and configurable `max_reservations_per_user` (default `nil`/unlimited for personal wishlists).
* **Invariants:**
  * Wishlist URLs (`/wishlists/:id` and `/s/:share_token`) are independent of `@username` so handle changes never break shared links.
  * Switching a wishlist from `shared` to private `friends` mode immediately wipes/invalidates `share_token` and revokes `secret_link` shares; redundant mode patches that do not change mode must not remint the token (rotation is explicit).
  * Logged-in non-blocked users opening a valid `share_token` link gain persistent access in their *"Shared with me"* tab (`WishlistShare` with `source: 'secret_link'`) while the token remains valid.
  * API serializers expose `share_token` only to the wishlist owner; non-owner show/shared/friend payloads omit it so Secret Links cannot be redistributed.
  * Account soft-delete cascades soft-delete of kept owned wishlists and records their IDs on `user.soft_deleted` AuditEvent metadata; account restore restores only that cascaded set.

### 4.4 `Item` & `ItemLink`
* **Responsibility:** A single giftable unit inside a `Wishlist`, with `title`, prominent `specifications` note (exact color/size/variant clarification), `priority` (`low`, `medium`, `high`, `must_have`), optional `price_cents` and `currency`, multiple purchase links (`ItemLink`), automatic store image/title extraction (`og:image`, `og:title`), and up to 3 WebP images.
* **Invariants:**
  * `1 Item = 1 Giftable Unit` in MVP.
  * Up to 3 images per item, max 2MB each, resized to <= 1600px longest side, converted to WebP, with all EXIF/GPS metadata stripped via `libvips`.
  * Reservation and gift state changes must **never** touch `items.updated_at` (preventing timing side-channel leaks to the wishlist owner).
* **Value Objects:** `ExternalUrl` (strict `http/https` validation + SSRF-safe OpenGraph fetch), `ImageDimensions`.

### 4.5 `Reservation` & `GiftRecord`
* **Responsibility:** Secret item reservation (`active`, `expired_grace`, `auto_released`, `canceled`, `completed_by_gift`) and dual-path gift fulfillment (`purchased_secret`, `delivered_pending_confirmation`, `received_confirmed`) with optional anonymous thank-you note.
* **Invariants:**
  * PostgreSQL partial unique index enforces at most one active/grace reservation per item: `WHERE status IN ('active', 'expired_grace')`.
  * **Zero Spoilers for Owner:** The wishlist owner never sees `active`, `expired_grace`, or `purchased_secret` states.
  * **Unified Status for Other Friends:** Other friends with access see a single unified `"Reserved / Unavailable"` state whenever an item is reserved or secretly purchased.
  * **No Third-Party Override:** A third-party friend cannot mark an already-reserved item as gifted or override another friend's active reservation. Only the active reserver can mark it purchased/delivered, OR the **wishlist owner** can mark *"I already received this"* (`received_confirmed`), which closes the reservation and notifies the reserver.
  * **72-Hour Expiration Grace Window:** When `estimated_date` elapses in the reserver's `time_zone`, status transitions to `expired_grace` and the reserver is notified. If not extended or marked purchased within 72 hours, it transitions to `auto_released`.

### 4.6 `Activity`, `ActivityParticipant` & `ActivityExclusion` (v1)
* **Responsibility:** Group gift exchanges (`secret_santa` 1->1 or `open_gifting`), external activity link access (scoped strictly to that activity), 5 budget modes (`none`, `fixed`, `min_only`, `max_only`, `range`), default 1 active reservation per participant in Secret Santa, pair exclusions, and blind dropout recovery.
* **Invariants:**
  * Minimum **3 `accepted` participants** required to run a `secret_santa` draw.
  * Draw algorithm enforces a **single Hamiltonian cycle** (no 2-person `A <-> B` sub-loops when >= 3 participants exist) and validates exclusion graph solvability before committing.
  * If a participant drops out after the draw, the creator chooses between **Blind Auto-Bridge** (server heals `A -> B -> C` into `A -> C` and notifies `A` without ever showing the creator who gifts whom) or **Full Redraw**.

### 4.7 `Report`, `AuditEvent`, `NotificationPreference` & `DeviceToken`
* **Responsibility:** Polymorphic abuse reports (`User`, `Wishlist`), immutable admin audit trail (`AuditEvent`), per-event notification toggles (`in_app`, `email`, `push`), and `api_token`-bound FCM `DeviceToken` (automatically unbound on logout/revocation).
* **Invariants:**
  * A user cannot report themselves, and partial unique index (`WHERE status = 'pending'`) prevents duplicate pending reports by the same reporter on the same target.
* **Value Objects:** `ReportReason` (`spam`, `harassment`, `impersonation`, `inappropriate_content`, `scam`).

---

## 5. Requirement Traceability Catalog (`[REQ-ID]`)

### Architecture & Lifecycle
* **`REQ-ARCH-001`**: Monorepo layout (`backend/` Rails 8, `mobile/` Flutter) with 100% server-side business logic and Pundit default-deny authorization.
* **`REQ-ARCH-002`**: `items` and `wishlists` schema includes nullable `price_cents`, `currency`, and `activity_id` readiness for v1 Activities.
* **`REQ-ARCH-003`**: Base Web and API v1 controllers trap `ActiveRecord::RecordNotUnique` and return deterministic `409 Conflict` / idempotent responses.
* **`REQ-LIFE-001`**: Soft-deleting a wishlist or item cascades soft-delete and permanently cancels active reservations so restoring leaves zero ghost reservations.
* **`REQ-LIFE-002`**: User account soft-delete provides a 30-day login restoration grace period, after which a Solid Queue job permanently purges/anonymizes PII.

### Authentication & Users
* **`REQ-AUTH-001`**: Dual authentication: stateful CSRF-protected cookie sessions for Web and SHA-256 `token_digest` bearer tokens (`api_tokens`) for `/api/v1`.
* **`REQ-AUTH-002`**: Mandatory acceptance of UGC Terms/EULA (`terms_accepted_at`) at user registration.
* **`REQ-AUTH-003`**: Anti-enumeration on password reset (always generic `200 OK`) and Rails 8 native `rate_limit` on `/login`, `/signup`, and `/passwords` from Sprint 1.
* **`REQ-USER-001`**: Public profile exposes unique `@username` while keeping `email_address` strictly private; changing `@username` enforces a 30-day cooldown.
* **`REQ-USER-002`**: Store preferred `locale` (`es` / `en`) on `User` from Sprint 1 for localized emails and push notifications.
* **`REQ-USER-003`**: Store `time_zone` on `User` (default `UTC`) for timezone-accurate reservation expiration and event dates.
* **`REQ-USER-004`**: Changing `@username` quarantines the previous `@username` for 30 days to prevent impersonation.

### Blocking & Social
* **`REQ-BLOCK-001`**: "Block Wins" invariant enforced in `ApplicationPolicy`: a block in either direction denies all access across profile, search, wishlists, secret links, and activities.
* **`REQ-BLOCK-002`**: Blocking a user transactionally destroys any existing friendship/request, removes `WishlistShare` records, and silently cancels active reservations between them.
* **`REQ-SOC-001`**: Search users by `@username`, send/accept/decline friend requests (with unordered unique pair index), and report users.

### Wishlists & Anti-Stalking Privacy
* **`REQ-WISH-001`**: Anti-stalking visibility: searching `@username` never exposes personal wishlists to strangers. Personal wishlists support `friends` (all accepted friends) and `shared` (selected friends + Secret Link).
* **`REQ-WISH-002`**: Logged-in non-blocked users accessing a `shared` wishlist via a valid `share_token` (Secret Link) can view and reserve items; switching to `friends`-only invalidates `share_token`.
* **`REQ-WISH-003`**: Opening a valid Secret Link while logged in registers the wishlist in the user's *"Shared with me"* list while the token remains valid.
* **`REQ-WISH-004`**: Wishlists support an optional `event_date` and warn reservers if `estimated_date > event_date`.
* **`REQ-WISH-005`**: Unauthenticated requests to a Secret Link render safe OpenGraph invitation metadata without leaking private items, and preserve `return_to` across login/sign-up.
* **`REQ-WISH-006`**: Wishlist and Secret Link URLs use immutable identifiers (`/wishlists/:id` and `/s/:share_token`) independent of `@username`.

### Items, Media & Store Extraction
* **`REQ-ITEM-001`**: Item CRUD with multiple purchase links (`ItemLink` validating strict `http/https`) and prominent `specifications` note below the image for exact color/size/variant clarifications.
* **`REQ-ITEM-002`**: Up to 3 images per item (<= 2MB, <= 1600px longest side), transcoded to WebP via `libvips` with mandatory EXIF/GPS metadata stripping.
* **`REQ-ITEM-003`**: Item `priority` desire levels (`low`, `medium`, `high`, `must_have`).
* **`REQ-ITEM-004`**: Items in `received_confirmed` state are visually separated into a *"Received Gifts"* section at the bottom of the wishlist.
* **`REQ-ITEM-005`**: Each `Item` represents 1 giftable unit in MVP.
* **`REQ-ITEM-006`**: Automatic best-effort extraction of product image and title (`og:image`, `og:title` with SSRF protection) when pasting or sharing a store link in MVP.

### Reservations & Gift Fulfillment
* **`REQ-RES-001`**: First-to-reserve concurrency enforced by PostgreSQL partial unique index on active/grace reservations, with private note and private `estimated_date`.
* **`REQ-RES-002`**: Zero reservation spoilers for the wishlist owner (no reservation fields in owner payloads and no mutation of `items.updated_at`).
* **`REQ-RES-003`**: Immediate notification to the active reserver/gifter if the owner deletes the item or edits critical fields (`title`, `specifications`, `links`).
* **`REQ-RES-004`**: Dedicated *"My Reservations"* dashboard/endpoint (`/api/v1/my_reservations`) for managing all active reservations across wishlists.
* **`REQ-RES-005`**: Context-aware reservation limits: configurable per-user active reservation limit per wishlist (unlimited by default on personal wishlists; default 1 per participant in Secret Santa activities).
* **`REQ-RES-006`**: 72-hour auto-release grace window after `estimated_date` expires in the reserver's timezone; if not extended or marked purchased within 72 hours, the reservation auto-releases.
* **`REQ-GIFT-001`**: Dual-path gift fulfillment: (Path 1) Reserver marks `purchased_secret` -> `delivered_pending_confirmation` (notifies owner anonymously) -> owner confirms `received_confirmed`; (Path 2) Owner directly marks `received_confirmed` in 1 step.
* **`REQ-GIFT-002`**: Unified `"Reserved / Unavailable"` status shown to other friends for both reserved and secretly purchased items; third parties cannot override another friend's active reservation.
* **`REQ-GIFT-003`**: When the wishlist owner directly marks an item as `received_confirmed` in 1 step, any active reservation is closed and the reserver is notified.
* **`REQ-GIFT-004`**: Optional anonymous *"Thank You"* note when the owner confirms gift receipt, delivered privately to the actual gifter without revealing the gifter's identity to the owner.

### Moderation, Notifications, Mobile & Group Activities
* **`REQ-DISC-001`**: Anti-stalking profile search and wishlist report system with Rails 8 `rate_limit` anti-spam protection.
* **`REQ-ADM-001`**: Web-only Admin panel backed by immutable `AuditEvent` records to inspect internal history, review reports, block abusive accounts, and revert erroneous/abusive state changes.
* **`REQ-NOTIF-001`**: Configurable per-event notifications (`in_app` + `email` + optional FCM `push`) dispatched via a single notification dispatcher.
* **`REQ-NOTIF-002`**: FCM `device_tokens` are bound to `api_token_id` and automatically unbound/deleted on logout or token revocation to prevent spoilers on shared devices.
* **`REQ-MOB-001`**: Full Flutter iOS/Android parity, Universal Links/App Links, client-side image compression, and native OS *"Share to App"* sheet support in MVP Sprint 9.
* **`REQ-MOB-002`**: Smart parsing of mixed text + URL payloads received from store apps (Amazon, MercadoLibre) in the mobile Share Sheet.
* **`REQ-ACT-001`**: Group Activities (`secret_santa` 1->1 and `open_gifting`) requiring >= 3 accepted participants for draw, with external activity links scoped strictly to that activity's info.
* **`REQ-ACT-002`**: Pair exclusions (`ActivityExclusion`) in Secret Santa with bounded deterministic graph solvability validation.
* **`REQ-ACT-003`**: Post-draw participant dropout recovery allowing the creator to choose between **Blind Auto-Bridge** (never revealing who gifts whom) or **Full Redraw**.
* **`REQ-ACT-004`**: Single Hamiltonian cycle enforcement on Secret Santa draws and exclusion validation before performing a Blind Auto-Bridge.
* **`REQ-ACT-005`**: 5 configurable budget modes per activity (`none`, `fixed`, `min_only`, `max_only`, `range`) validated on activity items and reservations.
