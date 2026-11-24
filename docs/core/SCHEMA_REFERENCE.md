# Database Schema Reference (`SCHEMA_REFERENCE.md`)

> **Canonical Source:** Auto-generated and enriched from [`backend/db/schema.rb`](../../backend/db/schema.rb) (Schema Version: `2026_11_24_133000`). Maps PostgreSQL tables, columns, and indexes to business rules and `[REQ-ID]` traceability codes in [`SPEC.md`](SPEC.md).

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
Stateful Web cookie sessions (`HttpOnly`, `SameSite=Lax`). Automatically cleared upon logout or account soft-delete.

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
