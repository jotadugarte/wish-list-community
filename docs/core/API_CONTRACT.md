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

### `POST /api/v1/account/restore` (`[REQ-LIFE-002]`)
Restores a soft-deleted account within the 30-day grace window and issues a fresh API token.
- **Auth Required:** No.
- **Request Body:** `{ "email_address": "user@example.com", "password": "secretPassword123" }`
- **Response (`200 OK`):** `{ "token": "raw_bearer_token_string", "user": { "id": 1, "username": "nata_24", "created_at": "..." } }`

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
Submits a polymorphic abuse report (`ReportReason` Value Object: `spam`, `harassment`, `impersonation`, `inappropriate_content`, `scam`) and records an `AuditEvent` (`"report.created"`).
- **Auth Required:** Yes.
- **Request Body:**
  ```json
  {
    "reportable_type": "User",
    "reportable_id": 3,
    "reason": "harassment",
    "details": "Optional context up to 1000 characters"
  }
  ```
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

### Notifications foundation (D5a / O1A / O8A)
- `GET /api/v1/notifications` · `POST /api/v1/notifications/:id/mark_read`
- `GET/PATCH /api/v1/notification_preferences`

