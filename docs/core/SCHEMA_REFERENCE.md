# Database Schema Reference (`SCHEMA_REFERENCE.md`)

> **Canonical Source:** Auto-generated and enriched from [`backend/db/schema.rb`](../../backend/db/schema.rb) (Schema Version: `2026_11_26_220000`). Maps PostgreSQL tables, columns, and indexes to business rules and `[REQ-ID]` traceability codes in [`SPEC.md`](SPEC.md).

---

## 1. `users` (`[REQ-USER-001]`, `[REQ-USER-002]`, `[REQ-USER-003]`, `[REQ-AUTH-002]`, `[REQ-LIFE-002]`)
Stores core user identity, authentication credentials, localization preferences, UGC terms acceptance, and soft-delete lifecycle state.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `email_address` | `string` | `false` | — | Strictly private normalized email (`EmailAddress` VO). Never serialized in public/friend responses. Anonymized to `purged_*@purged.invalid` after 30 days of soft-delete (`REQ-USER-001`, `REQ-LIFE-002`). |
| `username` | `string` | `false` | — | Public handle (`Username` VO, `3..30` chars, lowercase alphanumeric + underscores). Subject to a 30-day change cooldown (`REQ-USER-001`). |
| `password_digest` | `string` | `false` | — | BCrypt hash managed by `has_secure_password` (`REQ-AUTH-001`). |
| `role` | `string` | `false` | `"user"` | Authorization role (`"user"` or `"admin"`). |
| `locale` | `string` | `false` | `"es"` | Preferred UI and asynchronous notification language (`"es"` or `"en"`) (`REQ-USER-002`). |
| `time_zone` | `string` | `false` | `"UTC"` | User's IANA time zone for accurate reservation expiration and event dates (`REQ-USER-003`). |
| `username_changed_at` | `datetime` | `true` | `nil` | Timestamp of the last `@username` change; enforces the 30-day cooldown window (`REQ-USER-001`). |
| `terms_accepted_at` | `datetime` | `false` | — | Mandatory timestamp recording UGC EULA/Terms acceptance for App Store & Google Play compliance (`REQ-AUTH-002`). |
| `discarded_at` | `datetime` | `true` | `nil` | Soft-delete timestamp (`SoftDeletable`). Accounts can be restored within 30 days before permanent PII purge (`REQ-LIFE-002`). |
| `created_at` / `updated_at` | `datetime` | `false` | — | Standard audit timestamps. |

* **Indexes:**
  * `idx_users_on_lower_email_address`: Unique functional index on `LOWER(email_address)`.
  * `idx_users_on_lower_username`: Unique functional index on `LOWER(username)`.
  * `index_users_on_discarded_at`: B-tree index supporting `User.kept` and `PiiPurgeJob` queries.

---

## 2. `username_reservations` (`[REQ-USER-004]`)
Enforces a 30-day quarantine on a user's previous `@username` after they change their handle so third parties cannot immediately claim the old handle to impersonate them.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `username` | `string` | `false` | — | The quarantined lowercase `@username`. |
| `previous_user_id` | `bigint` | `false` | FK (`users`) | Owner who previously held this username (allowed to reclaim their own handle during quarantine). |
| `expires_at` | `datetime` | `false` | — | Quarantine expiration timestamp (`30.days.from_now` at time of change). |

* **Indexes:**
  * `idx_username_reservations_on_lower_username`: Unique functional index on `LOWER(username)`.
  * `index_username_reservations_on_expires_at`: Index for active quarantine lookups (`expires_at > Time.current`).

---

## 3. `sessions` (`[REQ-AUTH-001]`)
Stateful Web cookie sessions (`HttpOnly`, `Secure` in production, `SameSite=Lax`). Automatically cleared upon logout or account soft-delete.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Session ID stored in signed cookie. |
| `user_id` | `bigint` | `false` | FK (`users`) | Authenticated web user (`on_delete: :cascade`). |
| `ip_address` | `string` | `true` | `nil` | Client IP at session creation. |
| `user_agent` | `string` | `true` | `nil` | Client User-Agent string. |

---

## 4. `api_tokens` (`[REQ-AUTH-001]`, `[REQ-NOTIF-002]`)
Dedicated bearer tokens for `/api/v1` (Flutter iOS/Android clients). Never stores plain-text tokens in PostgreSQL.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `user_id` | `bigint` | `false` | FK (`users`) | Token owner (`on_delete: :cascade`). |
| `token_digest` | `string` | `false` | — | Deterministic **SHA-256 hex digest** computed by `AuthToken` Value Object (`REQ-AUTH-001`). |
| `device_name` | `string` | `true` | `nil` | Optional mobile device label (e.g., `"iPhone 16"`). |
| `last_used_at` | `datetime` | `true` | `nil` | Last activity timestamp. |
| `expires_at` | `datetime` | `false` | — | Token expiration timestamp (default 90 days). |
| `revoked_at` | `datetime` | `true` | `nil` | Set when the user logs out or revokes the token; revoking cascades destruction to bound `device_tokens` (`REQ-NOTIF-002`). |

* **Indexes:**
  * `index_api_tokens_on_token_digest`: Unique index on `token_digest`.

---

## 5. `device_tokens` (`[REQ-NOTIF-002]`)
Firebase Cloud Messaging (FCM) push notification tokens strictly coupled to an `api_token_id` so logging out on a shared mobile device immediately stops push notifications for the previous account.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `user_id` | `bigint` | `false` | FK (`users`) | Token owner (`on_delete: :cascade`). |
| `api_token_id` | `bigint` | `false` | FK (`api_tokens`) | Bound API session (`on_delete: :cascade`). Destroyed when `ApiToken#revoke!` is called. |
| `token` | `string` | `false` | — | Unique FCM registration token. |
| `platform` | `string` | `false` | `"unknown"` | Client OS (`"ios"`, `"android"`, `"unknown"`). |

---

## 6. `user_blocks` (`[REQ-BLOCK-001]`, `[REQ-BLOCK-002]`)
Directional blocks enforcing the platform-wide **"Block Wins"** law in `ApplicationPolicy`.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `blocker_id` | `bigint` | `false` | FK (`users`) | User initiating the block (`on_delete: :cascade`). |
| `blocked_id` | `bigint` | `false` | FK (`users`) | Target user being blocked (`on_delete: :cascade`). |

* **Indexes:**
  * `index_user_blocks_on_blocker_id_and_blocked_id`: Unique composite index preventing duplicate blocks.
  * `index_user_blocks_on_blocked_id_and_blocker_id`: Inverse composite index accelerating bidirectional `UserBlock.blocked_between?(user_a, user_b)` queries.

---

## 7. `audit_events` (`[REQ-ADM-001]`)
Strictly immutable (`readonly? => true` after creation) append-only audit log recording blocks, soft-deletes, restorations, and future reservation/gift actions for Sprint 8 Admin moderation.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `actor_id` | `bigint` | `true` | FK (`users`) | User who performed the action (`on_delete: :nullify`). |
| `action` | `string` | `false` | — | Canonical event key (e.g., `"user.blocked"`, `"user.soft_deleted"`, `"user.restored"`). |
| `auditable_type` / `auditable_id` | `string` / `bigint` | `false` | — | Polymorphic target entity. |
| `metadata` | `jsonb` | `false` | `{}` | Structured JSONB context for auditing and administrative revert. |

---

## 8. `friendships` (`[REQ-SOC-001]`, `[REQ-BLOCK-001]`, `[REQ-BLOCK-002]`)
Bidirectional friendships and pending friend requests between users. Enforces unordered pair uniqueness at the PostgreSQL level and is automatically cleaned up via `UserBlock` cascading hooks when a block occurs.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `requester_id` | `bigint` | `false` | FK (`users`) | User who initiated the friend request (`on_delete: :cascade`). Subject to a maximum of 20 pending outgoing requests (`MAX_PENDING_OUTGOING = 20`). |
| `addressee_id` | `bigint` | `false` | FK (`users`) | Target user receiving the friend request (`on_delete: :cascade`). Only the addressee may transition `status` from `"pending"` to `"accepted"`. |
| `status` | `string` | `false` | `"pending"` | Lifecycle state (`"pending"` or `"accepted"`). |
| `created_at` / `updated_at` | `datetime` | `false` | — | Standard audit timestamps. |

* **Indexes:**
  * `idx_friendships_on_unordered_user_pair`: Unique functional index on `LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)` preventing duplicate or crossed inverse friend requests.
  * `index_friendships_on_requester_id`, `index_friendships_on_addressee_id`, `index_friendships_on_status`: Supporting indexes for social graph queries and pending request count checks.

---

## 9. `reports` (`[REQ-SOC-001]`, `[REQ-DISC-001]`, `[REQ-ADM-001]`)
Polymorphic abuse reporting queue supporting `User` reports (Sprint 2) and `Wishlist` reports (Sprint 7) for Sprint 8 Admin moderation.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `reporter_id` | `bigint` | `false` | FK (`users`) | Authenticated user submitting the report (`on_delete: :cascade`). Cannot report themselves. |
| `reportable_type` / `reportable_id` | `string` / `bigint` | `false` | — | Polymorphic target entity (`"User"` or `"Wishlist"`). |
| `reason` | `string` | `false` | — | Canonical reason validated by `ReportReason` Value Object (`spam`, `harassment`, `impersonation`, `inappropriate_content`, `scam`). |
| `details` | `text` | `true` | `nil` | Optional reporter explanation (bounded to `<= 1000` characters). |
| `status` | `string` | `false` | `"pending"` | Moderation workflow state (`"pending"`, `"reviewed"`, `"dismissed"`). |
| `created_at` / `updated_at` | `datetime` | `false` | — | Standard audit timestamps. |

* **Indexes:**
  * `idx_reports_unique_pending_per_reporter_target`: Partial unique index on `(reporter_id, reportable_type, reportable_id) WHERE status = 'pending'`, preventing duplicate pending reports by the same reporter on the same target.
  * `index_reports_on_reportable_type_and_reportable_id`, `index_reports_on_reporter_id`, `index_reports_on_status`: Moderation queue lookup indexes.

---

## 10. `wishlists` (`[REQ-WISH-001]`, `[REQ-WISH-002]`, `[REQ-WISH-004]`, `[REQ-WISH-006]`, `[REQ-LIFE-001]`, `[REQ-ARCH-002]`)
Personal wishlist shells with anti-stalking privacy modes and opaque Secret Link `share_token`. Soft-delete cascades kept child `items` via SoftDeletable hooks (`REQ-LIFE-001`).

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Immutable wishlist identifier used in `/wishlists/:id` (`REQ-WISH-006`). |
| `owner_id` | `bigint` | `false` | FK (`users`) | Owning user (`on_delete: :cascade`). Account soft-delete cascades soft-delete of kept wishlists (`REQ-LIFE-002`). |
| `title` | `string` | `false` | — | Owner-visible list title. |
| `privacy_mode` | `string` | `false` | `"friends"` | `PrivacyMode` VO: `"friends"` (accepted friends) or `"shared"` (selected sharees + Secret Link). Default on create is `"friends"` (`REQ-WISH-001`). |
| `share_token` | `string` | `true` | `nil` | Opaque URL-safe Secret Link token (`ShareToken` VO). Present only when `privacy_mode = shared`; wiped on switch to `friends`; unique when present (`REQ-WISH-002`, `REQ-WISH-006`). Owner-only in API JSON. |
| `event_date` | `date` | `true` | `nil` | Optional event date for later reserver warnings (`REQ-WISH-004`). |
| `activity_id` | `bigint` | `true` | `nil` | Nullable readiness column for future Activity linkage (`REQ-ARCH-002`). |
| `max_reservations_per_user` | `integer` | `true` | `nil` | Optional per-user reservation cap; `nil` means unlimited for personal lists. |
| `discarded_at` | `datetime` | `true` | `nil` | Soft-delete timestamp (`SoftDeletable`, 30-day restore grace) (`REQ-LIFE-001`). |
| `created_at` / `updated_at` | `datetime` | `false` | — | Standard audit timestamps. |

* **Indexes:**
  * `index_wishlists_on_share_token_unique`: Partial unique index on `share_token WHERE share_token IS NOT NULL`.
  * `index_wishlists_on_owner_id`, `index_wishlists_on_owner_id_and_discarded_at`, `index_wishlists_on_discarded_at`, `index_wishlists_on_activity_id`.

---

## 11. `wishlist_shares` (`[REQ-WISH-003]`, `[REQ-BLOCK-002]`)
Grants a user access to a `shared`-mode wishlist via explicit friend share or Secret Link upsert. Unique per `(wishlist_id, user_id)`.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `wishlist_id` | `bigint` | `false` | FK (`wishlists`) | Shared wishlist (`on_delete: :cascade`). |
| `user_id` | `bigint` | `false` | FK (`users`) | Sharee (`on_delete: :cascade`). Cannot be the wishlist owner. |
| `source` | `string` | `false` | `"explicit"` | `"explicit"` (owner selected friend) or `"secret_link"` (opened `/s/:share_token`). Secret-link rows are revoked when the token is wiped or rotated (`REQ-WISH-002`, `REQ-WISH-003`). |
| `created_at` / `updated_at` | `datetime` | `false` | — | Standard audit timestamps. |

* **Indexes:**
  * `index_wishlist_shares_on_wishlist_id_and_user_id`: Unique composite preventing duplicate shares.
  * `index_wishlist_shares_on_wishlist_id`, `index_wishlist_shares_on_user_id`.
* **Cleanup:** Deleted between a user pair on `UserBlock.block!` and `Friendship#remove!` (`REQ-BLOCK-002` parity).

---

## 12. `items` (`[REQ-ITEM-001]`, `[REQ-ITEM-003]`, `[REQ-ITEM-005]`, `[REQ-ARCH-002]`, `[REQ-LIFE-001]`)
Single giftable units inside a wishlist (`1 item = 1 unit`). Soft-deletable; restore fails closed when the parent wishlist is discarded.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `wishlist_id` | `bigint` | `false` | FK (`wishlists`) | Parent wishlist (`on_delete: :cascade`). Soft-delete of the wishlist cascades soft-delete of kept items. |
| `title` | `string` | `false` | — | Display title. May be filled from a confirmed OpenGraph preview (`REQ-ITEM-006`). |
| `specifications` | `text` | `true` | `nil` | Prominent color/size/variant note (`REQ-ITEM-001`). Clearable via PATCH. |
| `priority` | `string` | `false` | `"medium"` | `ItemPriority` VO: `low`, `medium`, `high`, `must_have` (`REQ-ITEM-003`). |
| `price_cents` | `integer` | `true` | `nil` | Optional integer cents; nullable pair with `currency` (`REQ-ARCH-002`). Clearable via PATCH. |
| `currency` | `string` | `true` | `nil` | Optional ISO-like currency code paired with `price_cents`. Clearable via PATCH. |
| `position` | `integer` | `false` | `0` | Owner reorder order within the wishlist. Full-set reorder replaces positions atomically. |
| `discarded_at` | `datetime` | `true` | `nil` | Soft-delete timestamp (`SoftDeletable`, 30-day restore grace) (`REQ-LIFE-001`). |
| `created_at` / `updated_at` | `datetime` | `false` | — | Standard audit timestamps. Reservation mutations must not touch `updated_at` (Sprint 5). |

* **Indexes:** `index_items_on_wishlist_id`, `index_items_on_wishlist_id_and_position`, `index_items_on_wishlist_id_and_discarded_at`, `index_items_on_discarded_at`.
* **Attachments:** `has_many_attached :images` (ActiveStorage); max 3; server WebP + EXIF/GPS strip (`REQ-ITEM-002`). Store OG remote images attach only after owner confirm (`confirmed_preview`).

---

## 13. `item_links` (`[REQ-ITEM-001]`)
Purchase URLs for an item. Validated by `ExternalUrl` (`http`/`https` only).

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `item_id` | `bigint` | `false` | FK (`items`) | Parent item (`on_delete: :cascade`). |
| `url` | `string` | `false` | — | Absolute `http`/`https` purchase URL (`ExternalUrl` VO). |
| `position` | `integer` | `false` | `0` | Display order among links on the item. |
| `created_at` / `updated_at` | `datetime` | `false` | — | Standard audit timestamps. |

* **Indexes:** `index_item_links_on_item_id`, `index_item_links_on_item_id_and_position`.

---

## 14. ActiveStorage (`active_storage_blobs`, `active_storage_attachments`, `active_storage_variant_records`) (`[REQ-ITEM-002]`)
Rails ActiveStorage tables for item images (Disk service in local/test). Blobs store WebP bytes after `ItemImageProcessor` resize/strip; attachments bind `Item` records under name `images`. Variant records support optional derivatives; primary pipeline stores stripped WebP on the blob itself.

---

## 15. `reservations` (`[REQ-RES-001]`, `[REQ-RES-002]`, `[REQ-RES-006]`)
Secret holds on one item by one reserver. Mark purchased completes the hold as `completed_by_gift` and creates a `gift_records` row (Sprint 6).

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `item_id` | `bigint` | `false` | FK (`items`) | Held item. |
| `user_id` | `bigint` | `false` | FK (`users`) | Reserver (never the wishlist owner). |
| `status` | `string` | `false` | `"active"` | `ReservationStatus`: `active`, `expired_grace`, `auto_released`, `canceled`, `completed_by_gift`. |
| `estimated_date` | `date` | `false` | — | Private calendar date interpreted in the reserver's `time_zone` (`EstimatedDate` VO). |
| `private_note` | `string` | `true` | `nil` | Private note visible only to the reserver. |
| `grace_expires_at` | `datetime` | `true` | `nil` | Set when entering `expired_grace`; cleared on extend back to `active` or terminal cancel/auto-release. |
| `created_at` / `updated_at` | `datetime` | `false` | — | Row timestamps. Mutations must not touch `items.updated_at`. |

* **Indexes:** `index_reservations_on_item_id`, `index_reservations_on_user_id`, `index_reservations_on_user_id_and_status`, partial unique `index_reservations_one_active_hold_per_item` on `item_id` **where** `status IN ('active','expired_grace')`.
* **Why/when:** Created when a friend/sharee reserves; extended or canceled by the reserver; swept by `ReservationGraceSweepJob`; canceled on item soft-delete, block, unfriend, or account soft-delete of the reserver; completed when the reserver marks purchased.

---

## 16. `gift_records` (`[REQ-GIFT-001]`, `[REQ-GIFT-002]`, `[REQ-GIFT-003]`, `[REQ-GIFT-004]`, `[REQ-ADM-001]`)
Dual-path gift fulfillment rows. Open statuses block third-party availability; owner confirmations never leak `gifter_id` in owner-facing API JSON.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `item_id` | `bigint` | `false` | FK (`items`) | Gifted item. |
| `gifter_id` | `bigint` | `true` | FK (`users`) | Path 1 gifter; `nil` for Path 2 free-item receive (FC1). Admin-only identity. |
| `status` | `string` | `false` | `"purchased_secret"` | `GiftStatus`: `purchased_secret`, `delivered_pending_confirmation`, `received_confirmed`, `voided`. |
| `thank_you_note` | `string` | `true` | `nil` | Optional anonymous thank-you (`ThankYouNote` VO); delivered privately to gifter. |
| `purchase_link_ref` | `string` | `true` | `nil` | Optional online purchase URL (`PurchaseLinkRef` VO); admin audit only — never in client JSON. |
| `created_at` / `updated_at` | `datetime` | `false` | — | Row timestamps. Must not mutate `items.updated_at`. |

* **Indexes:** `index_gift_records_on_item_id`, `index_gift_records_on_gifter_id`, `(gifter_id, status)`, partial unique `index_gift_records_one_open_gift_per_item` on `item_id` **where** `status IN ('purchased_secret','delivered_pending_confirmation')`.
* **Why/when:** Created on mark purchased (Path 1) or owner mark received (Path 2); delivered/confirmed via `GiftService`; voided on item soft-delete, block, or unfriend (O8D) without reopen on restore.

---

## 17. `notifications` (`[REQ-NOTIF-001]`)
In-app notification inbox rows created by `NotificationDispatcher`.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `user_id` | `bigint` | `false` | FK (`users`) | Recipient. |
| `event_key` | `string` | `false` | — | Stable event id (e.g. `reservation.grace_started`). |
| `title` | `string` | `false` | — | Localized title at write time. |
| `body` | `text` | `true` | `nil` | Localized body. |
| `payload` | `jsonb` | `false` | `{}` | Opaque ids for deep links (e.g. `reservation_id`). |
| `read_at` | `datetime` | `true` | `nil` | Set when the user marks the row read. |
| `created_at` / `updated_at` | `datetime` | `false` | — | Standard audit timestamps. |

* **Indexes:** `index_notifications_on_user_id`, `(user_id, created_at)`, `(user_id, read_at)`.

---

## 18. `notification_preferences` (`[REQ-NOTIF-001]`, O8A)
Per-user channel toggles. Missing row = defaults all-on for Sprint 5 events.

| Column | Type | Null | Default | Business Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint` | `false` | PK | Primary identifier. |
| `user_id` | `bigint` | `false` | FK (`users`) | Unique per user. |
| `channels` | `jsonb` | `false` | `{}` | Nested map `event_key → { in_app, email, push }` booleans. |
| `created_at` / `updated_at` | `datetime` | `false` | — | Standard audit timestamps. |

* **Indexes:** unique `index_notification_preferences_on_user_id`.
* **Why/when:** Push preference is stored in Sprint 5; FCM send remains a no-op until Sprint 9.
