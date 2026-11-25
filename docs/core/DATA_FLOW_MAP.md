# Data Flow & Side-Effect Map

**Purpose:** Maps how entities mutate and propagate throughout the system. AI agents must consult this document to ensure they do not orphan data, leak spoilers, or bypass necessary side-effects.

## 1. Primary Request & Mutation Data Flow
1. **Client (Hotwire Web or Flutter `/api/v1`)** submits request payload (Cookie session or `Authorization: Bearer <raw_token>`).
2. **Authentication Layer** resolves `Current.user` (via `Session` cookie or SHA-256 `ApiToken.find_by(token_digest: ...)`), verifying `user.discarded_at.nil?`.
3. **Authorization Layer (Pundit)** executes policy check (`authorize`), enforcing the **"Block Wins"** law first before evaluating friendship, `WishlistShare`, or `share_token` access.
4. **Domain Service Object** executes business logic within a PostgreSQL transaction (checking preconditions, database uniqueness constraints, and postconditions) and writes an immutable `AuditEvent` when applicable.
5. **Notification Dispatcher (Solid Queue)** asynchronously enqueues localized (`user.locale`) in-app, email, and push notifications after transaction commit.

---

## 2. Cascading Side Effects

| Trigger Action | Required Side Effect | Mechanism |
|---|---|---|
| **User A blocks User B** (`REQ-BLOCK-002`) | 1. Destroy any `Friendship` (accepted or pending) between A and B.<br>2. Delete all `WishlistShare` records between A and B.<br>3. Cancel any active/grace `Reservation` held by A on B's items or by B on A's items (silently, no notification).<br>4. Record `AuditEvent`. | Synchronous DB Transaction (`UserBlock.block!` + `:destroy_friendships` hook) |
| **User accepts or removes a `Friendship`** (`REQ-SOC-001`, `REQ-ADM-001`) | 1. On acceptance (`Friendship#accept!`): transition `status` to `"accepted"` and record immutable `AuditEvent` (`"friendship.accepted"`).<br>2. On decline/cancel/unfriend (`Friendship#remove!`): record immutable `AuditEvent` (`"friendship.removed"`) and destroy the `Friendship` record. | Synchronous DB Transaction |
| **User submits an abuse `Report`** (`REQ-SOC-001`, `REQ-DISC-001`, `REQ-ADM-001`) | 1. Validate `ReportReason` Value Object and verify no duplicate `"pending"` report exists for `(reporter_id, reportable_type, reportable_id)`.<br>2. Persist `Report` (`status: "pending"`) and record immutable `AuditEvent` (`"report.created"`). | Synchronous DB Transaction (`Report.submit!`) |
| **User changes `@username`** (`REQ-USER-001`, `REQ-USER-004`) | 1. Verify `username_changed_at` is `nil` or `<= 30.days.ago`.<br>2. Quarantine old `@username` for 30 days (`UsernameReservation`).<br>3. Update `username` and `username_changed_at`. | Synchronous DB Transaction (`UsernameChangeService`) |
| **User logs out of `/api/v1` or revokes `ApiToken`** (`REQ-NOTIF-002`) | 1. Mark `ApiToken` revoked/deleted.<br>2. Immediately delete/deactivate any FCM `DeviceToken` bound to that `api_token_id` to prevent push spoilers on shared devices. | Synchronous DB Transaction |
| **User soft-deletes account** (`REQ-LIFE-002`) | 1. Set `discarded_at = Time.current` on `User` and cascade soft-delete to their `Wishlists` and `Items`.<br>2. Revoke all active `Sessions`, `ApiTokens`, and `DeviceTokens`.<br>3. Cancel all active reservations held by or on the user's items.<br>4. Schedule 30-day PII purge check via Solid Queue. | Synchronous DB Transaction + Solid Queue Scheduled Job |
| **Wishlist switched to `friends`-only (private)** (`REQ-WISH-002`) | 1. Set `share_token = nil` (invalidating any previously shared Secret Link).<br>2. Revoke secret-link-derived `WishlistShare` access. | Synchronous Model/Service Hook |
| **Wishlist or Item soft-deleted** (`REQ-LIFE-001`, `REQ-RES-003`) | 1. Set `discarded_at` on `Wishlist` and its `Items`.<br>2. Transition any active/grace `Reservation` on affected items to `canceled_by_deletion` (ensuring zero ghost reservations if restored later).<br>3. Enqueue notification to the affected reserver/gifter (*"The owner removed [Item] from their wishlist"*). | Synchronous DB Transaction + Solid Queue Notification Job |
| **Wishlist restored from soft-delete** (`REQ-LIFE-001`) | 1. Clear `discarded_at` on `Wishlist` and its `Items`.<br>2. Do **not** restore previously canceled reservations (items return clean). | Synchronous DB Transaction |
| **Owner edits critical fields (`title`, `specifications`, `links`) of an Item with an active reservation** (`REQ-RES-003`) | 1. Persist item changes.<br>2. Enqueue notification to the active reserver (*"The owner updated the specifications/details of [Item] you reserved"*). | After-commit callback -> Solid Queue Notification Job |
| **Image uploaded to `Item`** (`REQ-ITEM-002`) | 1. Validate <= 2MB and max 3 images.<br>2. Resize to <= 1600px longest side, re-encode to WebP, and **strip all EXIF/GPS metadata** via `libvips`. | ActiveStorage / `libvips` Image Processing Pipeline |
| **Item reserved or secretly purchased** (`REQ-RES-002`, `REQ-GIFT-002`) | 1. Insert/update `Reservation` (`active` or `purchased_secret`).<br>2. **MUST NOT** update `items.updated_at` (no side-channel timestamp leak to owner).<br>3. Record `AuditEvent`. | Synchronous DB Transaction (`touch: false` on `Item`) |
| **Reservation `estimated_date` elapses in reserver's `time_zone`** (`REQ-RES-006`) | 1. Transition status from `active` to `expired_grace` (`grace_expires_at = 72.hours.from_now`).<br>2. Notify reserver (*"Your reservation expired; you have 72 hours to extend or confirm purchase before auto-release"*). | Solid Queue Recurring Job (`ReservationExpirationJob`) |
| **Reservation remains in `expired_grace` for > 72 hours without action** (`REQ-RES-006`) | 1. Transition status from `expired_grace` to `auto_released` (freeing the partial unique index slot so other friends can reserve).<br>2. Notify reserver that the reservation was automatically released. | Solid Queue Recurring Job (`ReservationAutoReleaseJob`) |
| **Reserver marks item as `delivered_pending_confirmation`** (`REQ-GIFT-001`) | 1. Update gift/reservation status.<br>2. Send **anonymous** notification to wishlist owner (*"Someone marked [Item] as delivered! Confirm receipt?"*). | Synchronous DB Transaction + Solid Queue Notification Job |
| **Owner marks item as `received_confirmed` (1-step or confirming delivery)** (`REQ-GIFT-001`, `REQ-GIFT-003`, `REQ-GIFT-004`) | 1. Mark item as `received_confirmed` (moves to bottom *"Received Gifts"* section).<br>2. If an active reservation by a friend existed, close it (`completed_by_gift` or `canceled_by_owner_receipt`) and notify that friend.<br>3. If owner included an optional anonymous *"Thank You"* note, deliver it privately to the gifter without exposing the gifter's identity to the owner. | Synchronous DB Transaction + Solid Queue Notification Job |
| **Participant drops out after Secret Santa draw (`v1`)** (`REQ-ACT-003`, `REQ-ACT-004`) | If creator selects **Blind Auto-Bridge**:<br>1. Validate exclusion compatibility (`A -> C`).<br>2. Reassign `A` to gift `C` in DB without exposing `A` or `C` to the creator.<br>3. Notify `A` privately of their updated recipient. | Synchronous DB Transaction (`ActivityDropoutBridgeService`) + Solid Queue Notification Job |

---

## 3. Caching & Serializer Isolation Strategy
* **Strict Role-Based Serialization (Anti-Spoiler Boundary):**
  * **Owner Serializer View:** Never queries or serializes `Reservation` records unless status is `delivered_pending_confirmation` or `received_confirmed`.
  * **Friend / Link Viewer Serializer View:** Exposes a single boolean/enum (`availability_status: "available" | "reserved_unavailable" | "received"`) for items reserved by others, and exposes `my_reservation` details (`private_note`, `estimated_date`) **only** when `reservation.user_id == Current.user.id`.
  * **Admin Audit View (Web Only):** Exposes full `Reservation`, `GiftRecord`, online purchase link reference, and `AuditEvent` history.
