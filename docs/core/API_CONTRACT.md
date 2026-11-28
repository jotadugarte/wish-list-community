# API v1 Contract Reference (`API_CONTRACT.md`)

> **Purpose:** Living contract of all `/api/v1` REST endpoints consumed by the Flutter mobile app (`mobile/`) and external API clients. Maintained automatically by `sync-docs` whenever endpoints or payloads change.

## Global Conventions (`[REQ-ARCH-001]`, `[REQ-AUTH-001]`, `[REQ-ARCH-003]`, `[REQ-BLOCK-001]`)
- **Base Path:** `/api/v1`
- **Authentication:** `Authorization: Bearer <raw_token>` (except public auth endpoints: `POST /api/v1/session`, `POST /api/v1/passwords`, `POST /api/v1/account/restore`).
- **Localization (`[REQ-USER-002]`):** Error messages automatically use the authenticated user's `locale` (`es` or `en`).
- **Standard Error Responses:**
  - `401 Unauthorized`: `{ "error": "No autorizado" | "Unauthorized" }`
  - `404 Not Found`: `{ "error": "No encontrado" | "Not found" }` (Also returned whenever a resource is blocked via **"Block Wins"** or unauthorized via Pundit to prevent existence leaks).
  - `409 Conflict`: `{ "error": "Conflicto de recurso o solicitud duplicada" | "Resource conflict or duplicate request" }` (Trapped via `ActiveRecord::RecordNotUnique`).
  - `422 Unprocessable Content`: `{ "error": "<localized validation message>" }`.

---

## 1. Authentication & Account Lifecycle (`Sprint 1`)

### `POST /api/v1/session` (`[REQ-AUTH-001]`, `[REQ-AUTH-003]`, `[REQ-NOTIF-002]`)
Authenticates an active user, issues a SHA-256-backed API token, and optionally binds an FCM push notification `device_token`.
- **Auth Required:** No (Rate-limited: 10 req / 3 min per IP).
- **Request Body:**
  ```json
  {
    "email_address": "user@example.com",
    "password": "secretPassword123",
    "device_name": "iPhone 16",
    "device_token": "optional_fcm_token"
  }
  ```
  `fcm_token` is accepted as an alias of `device_token`.
- **Response (`201 Created`):**
  ```json
  {
    "token": "raw_bearer_token_string",
    "user": {
      "id": 1,
      "username": "nata_24",
      "created_at": "2026-11-24T12:00:00Z"
    }
  }
  ```

### `PATCH /api/v1/session` (`[REQ-NOTIF-002]`)
Rebinds the FCM `device_token` on the current authenticated API token (used after cold-start session restore).
- **Auth Required:** Yes (Rate-limited with session mutate: 20 req / 3 min).
- **Request Body:** `{ "device_token": "fcm_token" }` (`fcm_token` alias accepted).
- **Response:** `204 No Content`.

### `POST /api/v1/signup` (`[REQ-AUTH-001]`, `[REQ-AUTH-002]`, `[REQ-AUTH-003]`, `[REQ-USER-001]`, `[REQ-USER-002]`, `[REQ-USER-003]`)
Registers a new user with mandatory UGC Terms/EULA acceptance (`terms_accepted` → `terms_accepted_at`), then issues a SHA-256-backed API token (same response shape as session create).
- **Auth Required:** No (Rate-limited: 10 req / 3 min per IP).
- **Request Body:**
  ```json
  {
    "email_address": "user@example.com",
    "username": "nata_24",
    "password": "secretPassword123",
    "password_confirmation": "secretPassword123",
    "locale": "es",
    "time_zone": "America/Costa_Rica",
    "terms_accepted": true,
    "device_name": "iPhone 16",
    "device_token": "optional_fcm_token"
  }
  ```
- **Response (`201 Created`):**
  ```json
  {
    "token": "raw_bearer_token_string",
    "user": {
      "id": 1,
      "username": "nata_24",
      "created_at": "2026-11-26T12:00:00Z"
    }
  }
  ```
- **Error (`422 Unprocessable Content`):** `{ "errors": ["<localized validation or terms message>"] }` when `terms_accepted` is missing/false or identity validation fails. Does not reveal whether an email exists beyond ordinary uniqueness validation messages.

### `DELETE /api/v1/session` (`[REQ-AUTH-001]`, `[REQ-NOTIF-002]`)
Revokes the current API bearer token and immediately destroys any bound FCM `DeviceToken`.
- **Auth Required:** Yes.
- **Response:** `204 No Content`.

### `POST /api/v1/passwords` (`[REQ-AUTH-003]`)
Initiates a password reset with strict anti-enumeration (always returns `200 OK` regardless of whether the email exists).
- **Auth Required:** No (Rate-limited: 5 req / 3 min per IP).
- **Request Body:** `{ "email_address": "user@example.com" }`
- **Response (`200 OK`):** `{ "message": "<localized generic confirmation>" }`

### `GET /api/v1/me` (`[REQ-USER-001]`, `[REQ-USER-002]`, `[REQ-USER-003]`)
Returns the authenticated user's full private profile.
- **Auth Required:** Yes.
- **Response (`200 OK`):**
  ```json
  {
    "id": 1,
    "email_address": "user@example.com",
    "username": "nata_24",
    "locale": "es",
    "time_zone": "America/Bogota"
  }
  ```

### `DELETE /api/v1/account` (`[REQ-LIFE-002]`)
Soft-deletes the authenticated user's account, revokes all active credentials/tokens, and starts the 30-day restoration grace period before PII purge.
- **Auth Required:** Yes.
- **Response:** `204 No Content`.

### `POST /api/v1/account/restore` (`[REQ-LIFE-002]`, `[REQ-ADM-001]`)
Restores a **self** soft-deleted account within the 30-day SoftDeletable grace window and issues a fresh API token.
- **Auth Required:** No.
- **Request Body:** `{ "email_address": "user@example.com", "password": "secretPassword123" }`
- **Response (`200 OK`):** `{ "token": "raw_bearer_token_string", "user": { "id": 1, "username": "nata_24", "created_at": "..." } }`
- **Admin-enforced soft-delete (`admin_enforcement` on the latest `user.soft_deleted` AuditEvent):** returns the same generic `401 Unauthorized` / `invalid_credentials` as a bad password (no moderation leak). Restore is via Admin audit revert only (`REQ-ADM-001` / O4A).
- **Other failures within the grace window** (e.g. expired window after auth): `422` with localized SoftDeletable error messages when applicable.

---

## 2. Social Graph, Anti-Stalking Search, Blocking & Reports (`Sprint 1 & Sprint 2`)

### `GET /api/v1/users/search?q=<query>` (`[REQ-SOC-001]`, `[REQ-WISH-001]`, `[REQ-BLOCK-001]`)
Prefix search for active (`kept`) non-blocked users by `@username` (validated via `SearchQuery` Value Object, `2..30` chars). Batch-loads `friendship_status` in 1 query (`Friendship.statuses_for`). Never exposes `email_address` or personal wishlists.
- **Auth Required:** Yes.
- **Response (`200 OK`):**
  ```json
  {
    "users": [
      {
        "id": 2,
        "username": "nata_friend",
        "created_at": "2026-11-25T10:00:00Z",
        "friendship_status": "accepted"
      }
    ]
  }
  ```

### `GET /api/v1/users/:username` (`[REQ-USER-001]`, `[REQ-SOC-001]`, `[REQ-WISH-001]`, `[REQ-BLOCK-001]`)
Returns the anti-stalking public profile card for `:username` (or `404 Not Found` if blocked in either direction or soft-deleted).
- **Auth Required:** Yes.
- **Response (`200 OK`):**
  ```json
  {
    "id": 2,
    "username": "ceci_nata",
    "created_at": "2026-11-25T10:00:00Z",
    "friendship_status": "none | pending_outgoing | pending_incoming | accepted"
  }
  ```

### `GET /api/v1/friendships` (`[REQ-SOC-001]`)
Lists the authenticated user's active accepted friends, incoming pending friend requests, and outgoing pending friend requests (automatically excluding soft-deleted accounts).
- **Auth Required:** Yes.
- **Response (`200 OK`):**
  ```json
  {
    "friends": [
      {
        "id": 10,
        "status": "accepted",
        "direction": "outgoing",
        "friend": { "id": 2, "username": "bob_gifts", "created_at": "..." },
        "created_at": "...",
        "updated_at": "..."
      }
    ],
    "incoming_requests": [],
    "outgoing_requests": []
  }
  ```

### `POST /api/v1/friendships` (`[REQ-SOC-001]`, `[REQ-BLOCK-001]`)
Sends a friend request to `addressee_id` (enforces max 20 pending outgoing requests, unordered unique pair constraint, and `"Block Wins"`).
- **Auth Required:** Yes.
- **Request Body:** `{ "addressee_id": 2 }`
- **Response (`201 Created`):** `{ "friendship": { "id": 11, "status": "pending", "direction": "outgoing", "friend": { ... } } }`

### `PATCH /api/v1/friendships/:id` (`[REQ-SOC-001]`, `[REQ-BLOCK-001]`, `[REQ-ADM-001]`)
Allows the `addressee` of a pending friend request to accept it and records an `AuditEvent` (`"friendship.accepted"`).
- **Auth Required:** Yes (must be `addressee`).
- **Response (`200 OK`):** `{ "friendship": { "id": 11, "status": "accepted", ... } }`

### `DELETE /api/v1/friendships/:id` (`[REQ-SOC-001]`, `[REQ-ADM-001]`)
Allows either participant (`requester` or `addressee`) to decline a pending request, cancel an outgoing request, or remove an accepted friend, recording an `AuditEvent` (`"friendship.removed"`).
- **Auth Required:** Yes (must be participant).
- **Response:** `204 No Content`.

### `POST /api/v1/user_blocks` (`[REQ-BLOCK-001]`, `[REQ-BLOCK-002]`, `[REQ-ADM-001]`)
Directionally blocks `blocked_id`, transactionally destroying any existing `Friendship`, shares, and active reservations between the two users, and recording an `AuditEvent` (`"user.blocked"`).
- **Auth Required:** Yes.
- **Request Body:** `{ "blocked_id": 3 }`
- **Response (`201 Created`):** `{ "blocked_id": 3, "status": "blocked" }`

### `POST /api/v1/reports` (`[REQ-SOC-001]`, `[REQ-DISC-001]`, `[REQ-ADM-001]`)
Submits a polymorphic abuse report (`ReportReason` Value Object: `spam`, `harassment`, `impersonation`, `inappropriate_content`, `scam`) and records an `AuditEvent` (`"report.created"`). Allowed `reportable_type` values: `User` (Sprint 2) and `Wishlist` (Sprint 7). Wishlist reports require the reporter to currently pass `WishlistPolicy#show?` and **not** be the owner; soft-deleted / inaccessible lists return `404` (anti-existence leak). Duplicate pending reports return `422`. Enqueue-only — no owner notification and no auto-hide. Hotwire Admin triage (`/admin/reports`) dismisses or reviews with Suspend / soft-delete; there is **no** admin JSON API.
- **Auth Required:** Yes.
- **Rate limit:** `20` requests / `3` minutes → `429` with `{ "error": "..." }`.
- **Request Body:**
  ```json
  {
    "reportable_type": "User",
    "reportable_id": 3,
    "reason": "harassment",
    "details": "Optional context up to 1000 characters"
  }
  ```
  Wishlist example: `{ "reportable_type": "Wishlist", "reportable_id": 12, "reason": "spam" }`.
- **Response (`201 Created`):**
  ```json
  {
    "report": {
      "id": 1,
      "reportable_type": "User",
      "reportable_id": 3,
      "reason": "harassment",
      "details": "Optional context up to 1000 characters",
      "status": "pending",
      "created_at": "2026-11-25T10:30:00Z"
    }
  }
  ```

### Mutation `rate_limit` (`[REQ-DISC-001]`, Sprint 7)
Rails 8 `rate_limit` applies to API v1 **write** mutations (friendships, blocks, wishlists/shares/restore, items including restore/reorder, reservations, gifts, notification preferences update, notifications `mark_read`, session/account destroy, reports) and Hotwire Secret Link mutations (including report create), typically `10–20` / `3` minutes within the O2A tuning band. Authenticated caps key by `current_user.id` (IP fallback). Distinct `name:` per declaration when a controller has more than one. Existing auth (`login`/`signup`/`passwords`), account restore, and link-preview caps remain unchanged. Exceeding a cap returns `429` (JSON) or Hotwire redirect `:see_other` with flash wait copy.

### Hotwire Secret Link report (`[REQ-DISC-001]`, `[REQ-WISH-002]`)
- **`POST /s/:share_token/report`** — cookie session + CSRF; creates a pending Wishlist report for authenticated non-owners (same reasons). Guests are redirected to login with `return_to`. Soft-deleted / invalid token → `404`.

---

## 3. Wishlists (`Sprint 3`)

Wishlist shells; items via nested `/wishlists/:id/items` (Sprint 4). Privacy modes: `friends` | `shared`. Default on create: `friends` with `share_token: null`.
`share_token` is included only in owner-facing payloads (create/index/show/update/rotate for the owner). Shared-with-me and friend discovery responses omit it so non-owners cannot redistribute the Secret Link.

### Wishlist JSON shell
```json
{
  "id": 1,
  "title": "Cumpleaños",
  "privacy_mode": "friends",
  "share_token": null,
  "event_date": "2026-12-25",
  "max_reservations_per_user": null,
  "owner": { "id": 1, "username": "nata_24", "created_at": "2026-11-26T12:00:00Z" },
  "discarded_at": null,
  "created_at": "2026-11-26T12:00:00Z",
  "updated_at": "2026-11-26T12:00:00Z"
}
```

### `GET /api/v1/wishlists` (`[REQ-WISH-001]`)
Lists the authenticated user's kept wishlists.
- **Auth Required:** Yes.
- **Response (`200 OK`):** `{ "wishlists": [ /* shell */ ] }`

### `POST /api/v1/wishlists` (`[REQ-WISH-001]`, `[REQ-WISH-004]`)
Creates a wishlist (`privacy_mode` forced to `friends`).
- **Auth Required:** Yes.
- **Request Body:** `{ "wishlist": { "title": "Cumpleaños", "event_date": "2026-12-25" } }`
- **Response (`201 Created`):** `{ "wishlist": { /* shell */ } }`

### `GET /api/v1/wishlists/:id` (`[REQ-WISH-001]`, `[REQ-BLOCK-001]`)
Shows a wishlist when `WishlistPolicy#show?` allows (owner, friends-mode friend, or sharee).
- **Auth Required:** Yes.
- **Response (`200 OK`):** `{ "wishlist": { /* shell */ } }` — `404` on deny/block.

### `PATCH /api/v1/wishlists/:id` (`[REQ-WISH-001]`, `[REQ-WISH-002]`, `[REQ-WISH-004]`)
Owner updates `title` / `event_date` / `privacy_mode` (mode change mints or wipes `share_token`).
- **Auth Required:** Yes (owner).
- **Response (`200 OK`):** `{ "wishlist": { /* shell */ } }`

### `DELETE /api/v1/wishlists/:id` (`[REQ-LIFE-001]`)
Owner soft-deletes the wishlist.
- **Auth Required:** Yes (owner).
- **Response:** `204 No Content`.

### `POST /api/v1/wishlists/:id/restore` (`[REQ-LIFE-001]`)
Owner restores within SoftDeletable 30-day grace.
- **Auth Required:** Yes (owner).
- **Response (`200 OK`):** `{ "wishlist": { /* shell */ } }`

### `POST /api/v1/wishlists/:id/share_token/rotate` (`[REQ-WISH-002]`, `[REQ-WISH-006]`)
Rotates Secret Link while staying `shared`; revokes `secret_link` shares; keeps `explicit`.
- **Auth Required:** Yes (owner).
- **Response (`200 OK`):** `{ "wishlist": { /* shell with new share_token */ } }`

### `POST /api/v1/wishlists/:id/shares` (`[REQ-WISH-003]`)
Creates an explicit share for an accepted friend while wishlist is `shared`.
- **Auth Required:** Yes (owner).
- **Request Body:** `{ "user_id": 2 }`
- **Response (`201 Created`):** `{ "share": { "id": 1, "wishlist_id": 1, "user_id": 2, "source": "explicit", "user": { /* public card */ }, "created_at": "..." } }`

### `DELETE /api/v1/wishlists/:id/shares/:user_id` (`[REQ-WISH-003]`)
Removes a share row.
- **Auth Required:** Yes (owner).
- **Response:** `204 No Content`.

### `GET /api/v1/shared_wishlists` (`[REQ-WISH-003]`)
*"Shared with me"* — wishlists the viewer has a `WishlistShare` for.
- **Auth Required:** Yes.
- **Response (`200 OK`):** `{ "wishlists": [ /* shell */ ] }`

### `GET /api/v1/users/:username/wishlists` (`[REQ-WISH-001]`, `[REQ-BLOCK-001]`)
Policy-scoped wishlists for `@username` (O3A). Strangers get `[]`; block → `404`.
- **Auth Required:** Yes.
- **Response (`200 OK`):** `{ "wishlists": [ /* shell */ ] }`

### Web Secret Link (Hotwire, not `/api/v1`)
- `GET /s/:share_token` — guest OG invitation *"Lista de deseos de @username"*; logged-in upserts `WishlistShare(source: secret_link)` (`[REQ-WISH-005]`, `[REQ-WISH-003]`).
- `GET|POST /session` and `GET|POST /signup` — HTML auth with allowlisted `return_to` matching `\A/s/[A-Za-z0-9\-_]+\z` (`[REQ-WISH-005]`, `[REQ-AUTH-001]`).

---

## 4. Items, Media & Link Previews (`Sprint 4`)

Item CRUD (`1 item = 1 unit`), multipart images (server WebP/EXIF strip), optional `price_cents`/`currency`, `position` reorder, and sync OpenGraph previews (confirm before persist).

### Item JSON
```json
{
  "id": 1,
  "wishlist_id": 1,
  "title": "Auriculares",
  "specifications": "Negro",
  "priority": "high",
  "price_cents": 5000,
  "currency": "USD",
  "position": 0,
  "links": [{ "id": 1, "url": "https://shop.example/a", "position": 0 }],
  "images": [{ "id": 10, "content_type": "image/webp", "byte_size": 1234, "url": "/rails/active_storage/blobs/..." }],
  "discarded_at": null,
  "created_at": "...",
  "updated_at": "..."
}
```

### `GET/POST /api/v1/wishlists/:wishlist_id/items` (`[REQ-ITEM-001]`, `[REQ-ITEM-003]`, `[REQ-ARCH-002]`)
Index (policy-scoped) / create (owner). Create accepts `item` JSON + optional `confirmed_preview` + multipart `images[]`.

### `GET/PATCH/DELETE /api/v1/items/:id` (`[REQ-ITEM-001]`, `[REQ-LIFE-001]`)
Show / update / soft-delete.

### `POST /api/v1/items/:id/restore` (`[REQ-LIFE-001]`)
Owner restore within SoftDeletable grace.

### `DELETE /api/v1/items/:id/images/:image_id` (`[REQ-ITEM-002]`)
Detach one image.

### `PATCH /api/v1/wishlists/:wishlist_id/items/reorder` (`[REQ-ITEM-001]`)
Body: `{ "item_ids": [3,1,2] }`.

### `POST /api/v1/link_previews` (`[REQ-ITEM-006]`)
Body: `{ "url": "https://..." }` → `{ "title", "image_url", "source_url" }` (best-effort; SSRF-safe). Auth required.

## 5. Reservations & Notifications (Sprint 5)

### Reservations
- `POST /api/v1/items/:item_id/reservations` — create (`estimated_date`, optional `private_note`); **409** on concurrent hold ([REQ-RES-001], [REQ-ARCH-003])
- `PATCH /api/v1/reservations/:id` — extend date / note; grace → active ([REQ-RES-006] O5A)
- `DELETE /api/v1/reservations/:id` — voluntary cancel ([REQ-RES-001] O6A)
- `GET /api/v1/my_reservations` — current user `active` + `expired_grace` ([REQ-RES-004])
- Item payloads for **non-owners** may include `availability`: `available` | `reserved_by_me` | `unavailable` (omitted for owner) ([REQ-RES-002] O3A)

### Hotwire Secret Link (O4B)
- `POST /s/:share_token/items/:item_id/reservations`
- `PATCH /s/:share_token/reservations/:id`
- `DELETE /s/:share_token/reservations/:id`

### Notifications (Sprint 5 foundation + Sprint 9 O1A/O7A/O10B)
- `GET /api/v1/notifications` · `POST /api/v1/notifications/:id/mark_read`
- `GET/PATCH /api/v1/notification_preferences` — response includes `channels` and `defaults_events` catalog (friend.request_*, reservation.*, gift.*)
- Push delivery via injectable FCM adapter (`PushNotifier`); without Google keys, in-app + email still work (no crash). `device_token` binds on session/signup, rebinds via `PATCH /api/v1/session`, and is destroyed on logout/revoke (`REQ-NOTIF-002`).

### Member Hotwire + legal (Sprint 9 O2B/O8A/O12A/O13A) — not `/api/v1`
- Public `GET /terms` · `GET /privacy` (bilingual es+en placeholders)
- Logged-in ` /app/*` MemberWebShell: wishlists, items, reservations/gifts, notifications inbox + prefs, account soft-delete

## 5b. Activities (v1 Sprint A shell) `[REQ-ACT-001]`…`[REQ-ACT-005]`

Group gift exchange shell (no activity-scoped items/reservations yet — those are Sprint B). Modes: `secret_santa` | `open_gifting`. Budget modes stored: `none` | `fixed` | `min_only` | `max_only` | `range` (enforcement in Sprint B). Assignment map is never returned wholesale to creator/co-org.

### Activity API
- `GET /api/v1/activities` — activities where the viewer is creator or accepted participant
- `POST /api/v1/activities` — create shell; mints opaque `share_token`; creator auto-accepted as co-org
- `GET /api/v1/activities/:id` — board payload; `share_token` only for creator
- `POST /api/v1/activities/:id/participants` — invite (`user_id`); creator/co-org
- `POST /api/v1/activities/:id/participants/accept` — invitee accepts (O2B money freeze on first invitee accept)
- `DELETE /api/v1/activities/:id/participants/me` — leave (free pre-seal; post-draw forces cure; post-Arrancar no bridge)
- `POST /api/v1/activities/:id/exclusions` — pair exclusion (`giver_id`, `forbidden_recipient_id`)
- `POST /api/v1/activities/:id/draw` — secret_santa Hamiltonian draw (≥3 accepted); optional `seed`
- `POST /api/v1/activities/:id/arrancar` — open_gifting seal (≥2 accepted); no assignments
- `GET /api/v1/activities/:id/my_assignment` — giver-only recipient (private)
- `POST /api/v1/activities/:id/blind_bridge` — Blind Auto-Bridge when `needs_dropout_recovery`
- `POST /api/v1/activities/:id/full_redraw` — Full Redraw (≥3 remaining) or error directing cancel
- `POST /api/v1/activities/:id/co_organizers` — creator-only appoint (`user_id`)
- `POST /api/v1/activities/:id/transfer` — creator-only transfer (`new_creator_id` must be co-org)
- `POST /api/v1/activities/:id/cancel` — creator/co-org cancel

### Activity Hotwire surfaces
- Public `GET /a/:share_token` — safe invite preview (no roster); logged-in accepted participants redirect to `/app/activities/:id`
- Member `GET|POST /app/activities` · `GET /app/activities/:id` — create + board with personal wishlist bridges

## 6. Gifts (Sprint 6)

Dual-path fulfillment via `GiftRecord` (`purchased_secret` → `delivered_pending_confirmation` → `received_confirmed`; `voided` for O8D). Optional `purchase_link_ref` and gifter identity (`@username` + email) are Hotwire Admin-only (`/admin/gifts/:id`, audit gift detail) and **never** returned in `/api/v1` JSON (including when the bearer user has `role=admin`). Optional anonymous thank-you on confirm ([REQ-GIFT-001], [REQ-GIFT-004], [REQ-ADM-001]).

### Gift API
- `POST /api/v1/reservations/:id/mark_purchased` — Path 1 start from `active`|`expired_grace`; body optional `{ "gift": { "purchase_link_ref" } }`; reservation → `completed_by_gift`; **409** if open gift exists ([REQ-GIFT-001], [REQ-GIFT-002], [REQ-RES-006] O6A)
- `POST /api/v1/gifts/:id/mark_delivered` — gifter only; notifies owner anonymously (`gift.delivered_pending_confirmation`) ([REQ-GIFT-001], [REQ-NOTIF-001] O7A)
- `POST /api/v1/gifts/:id/confirm_received` — owner; optional `{ "gift": { "thank_you_note" } }` ([REQ-GIFT-001], [REQ-GIFT-004] O5A)
- `POST /api/v1/items/:id/mark_received` — Path 2 owner 1-step; closes hold/open gift or FC1 free item with no gifter ([REQ-GIFT-003])
- `GET /api/v1/my_reservations` — also returns `open_gifts` for the current gifter ([REQ-GIFT-001])
- Item payloads may include `received_gift: true` when `received_confirmed`; open gifts map to the same `availability` enum (gifter → `reserved_by_me`, others → `unavailable`) ([REQ-GIFT-002], [REQ-ITEM-004], FC2)

### Hotwire Secret Link gift parity (O3C)
- `POST /s/:share_token/reservations/:reservation_id/mark_purchased`
- `POST /s/:share_token/gifts/:id/mark_delivered`
- `POST /s/:share_token/gifts/:id/confirm_received`
- `POST /s/:share_token/items/:item_id/mark_received`

### Relationship guards (O8D)
- `POST /api/v1/user_blocks` and `DELETE /api/v1/friendships/:id` require `confirm_void_gifts=true` when the actor is the gifter with an open gift toward the other user; otherwise **422**.

## 7. Web-only Admin panel (Sprint 8, Hotwire) `[REQ-ADM-001]`

Cookie session + `role=admin` only. Non-admins receive **404** (no panel leak). No Flutter Admin and no `/api/v1` admin endpoints. Provision admins via seed / `rails console` (`user.update!(role: "admin")`).

- `GET /admin` · `GET /admin/reports` — pending report queue (User + Wishlist)
- `GET /admin/reports/:id` — triage actions: dismiss / suspend / soft-delete account / soft-delete wishlist
- `POST /admin/reports/:id/dismiss|suspend|soft_delete_user|soft_delete_wishlist` — rate-limited writes; AuditEvents; **no** Notifications
- `GET /admin/audit_events` — filterable AuditEvent viewer (`action_filter`)
- `POST /admin/audit_events/:id/revert` — unsuspend / restore soft-delete (30-day window) / reopen dismissed→pending
- `GET /admin/gifts/:id` — read-only gifter `@username` + email + `purchase_link_ref`
- `GET /admin/style_guide` — admin-only brand/style guide (cookie `role=admin`, others **404**). Query `preview=web|app`, `appearance=light|dark`, `copy=es|en`. Web preview and HTML/CSS phone mock are inert. Print CSS is on the page. Colors come from `design/design_tokens.json` (version stamp on the page). No secret URL and no `/api/v1` equivalent.

Suspended accounts fail web/API login with the same generic invalid-credentials copy as bad passwords (FC2). Self soft-delete restore within 30 days is unchanged; **admin-enforced** soft-deletes fail restore with that same generic `401` (member must not learn moderation status from restore).

