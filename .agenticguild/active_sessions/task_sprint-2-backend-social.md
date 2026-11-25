# Active Session: MVP Sprint 2 (Backend) — Social & Anti-Stalking Profile Search

<session_metadata>
  <task_name>sprint-2-backend-social</task_name>
  <classification>Feature</classification>
  <roadmap_item>MVP Sprint 2 — Social & Anti-Stalking Profile Search</roadmap_item>
  <branch>feat/sprint-2-backend-social</branch>
  <started_at>2026-11-25</started_at>
  <req_ids>REQ-SOC-001, REQ-WISH-001, REQ-BLOCK-001, REQ-BLOCK-002, REQ-DISC-001, REQ-ADM-001</req_ids>
</session_metadata>

## Task Description
Build the complete backend layer for **MVP Sprint 2 — Social & Anti-Stalking Profile Search**:
1. **Bidirectional Friendships (`Friendship` + `FriendshipPolicy`)** (`REQ-SOC-001`, `REQ-BLOCK-001`, `REQ-BLOCK-002`):
   - PostgreSQL table `friendships` with `requester_id`, `addressee_id`, `status` (`pending` | `accepted`), and a functional unordered unique pair index `ON friendships (LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id))` preventing duplicate or crossed friend requests.
   - Anti-spam limit: max 20 pending outgoing friend requests per user.
   - "Block Wins" enforcement: cannot request or accept friendship if blocked in either direction; registering a `UserBlock.register_cleanup_hook(:destroy_friendships)` hook automatically destroys any existing `Friendship` (pending or accepted) when a block occurs.
2. **Anti-Stalking `@username` Profile Search & Public Card Enrichment** (`REQ-SOC-001`, `REQ-WISH-001`, `REQ-BLOCK-001`):
   - Search query Value Object `SearchQuery` (`backend/app/values/search_query.rb`) normalizing `@username` prefix searches.
   - `GET /api/v1/users/search?q=...` returning bounded prefix matches (max 20) of active (`kept`) non-blocked users with only public anti-stalking fields (`id`, `username`, `friendship_status`, `created_at`), never exposing `email_address` or personal wishlists.
   - Enrich `GET /api/v1/users/:username` to include `friendship_status` (`none`, `pending_outgoing`, `pending_incoming`, `accepted`) relative to `current_user`.
3. **Friendships API v1 (`Api::V1::FriendshipsController`)** (`REQ-SOC-001`, `REQ-BLOCK-001`):
   - `GET /api/v1/friendships` (list accepted friends + pending incoming/outgoing requests).
   - `POST /api/v1/friendships` (send friend request to target user).
   - `PATCH /api/v1/friendships/:id` (addressee accepts pending friend request).
   - `DELETE /api/v1/friendships/:id` (addressee declines, requester cancels, or either friend removes friendship).
4. **User Reporting (`Report` + `ReportReason` Value Object + `Api::V1::ReportsController`)** (`REQ-SOC-001`, `REQ-DISC-001`, `REQ-ADM-001`):
   - Polymorphic `reports` table (`reporter_id`, `reportable_type`, `reportable_id`, `reason`, `details`, `status: 'pending' | 'reviewed' | 'dismissed'`) with uniqueness constraint preventing duplicate pending reports by the same reporter on the same target.
   - `POST /api/v1/reports` with Pundit authorization (`ReportPolicy`) and immutable `AuditEvent` (`"report.created"`).

## Domain Model
- `SearchQuery` (`backend/app/values/search_query.rb`): Value Object wrapping `@username` prefix search input (`2..30` chars, `\A[a-z0-9_.]+\z`, strips leading `@` and whitespace, exposes `#value`, `#prefix_pattern`, `#to_s`).
- `ReportReason` (`backend/app/values/report_reason.rb`): Value Object wrapping abuse report reason (`spam`, `harassment`, `impersonation`, `inappropriate_content`, `scam`, exposes `#value`, `#to_s`).
- `Username` (`backend/app/values/username.rb`): Existing Value Object from Sprint 1 reused for exact `@username` profile lookup.

## Core Function Contracts (Pre-conditions & Post-conditions)
- `Friendship.request!(requester:, addressee:)`:
  - **Pre-condition:** Both `requester` and `addressee` are persisted `kept` `User` records, `requester.id != addressee.id`, `!UserBlock.blocked_between?(requester, addressee)`, and outgoing pending count < 20.
  - **Post-condition:** Persisted `Friendship` exists with `status == "pending"`.
- `Friendship#accept!(actor:)`:
  - **Pre-condition:** Record is `persisted?`, `status == "pending"`, `actor.id == addressee_id`, and `!UserBlock.blocked_between?(requester, addressee)`.
  - **Post-condition:** `status == "accepted"` and `AuditEvent` `"friendship.accepted"` is recorded.
- `Report.submit!(reporter:, reportable:, reason:, details: nil)`:
  - **Pre-condition:** `reporter` and `reportable` are persisted records, `reporter != reportable`, and `ReportReason.new(reason)` is valid.
  - **Post-condition:** Persisted `Report` exists with `status == "pending"` and `AuditEvent` `"report.created"` is recorded.

<implementation_plan>
  <step id="1" status="complete">Write failing RSpec unit tests for `SearchQuery` and `ReportReason` Value Objects (`spec/values/search_query_spec.rb`, `spec/values/report_reason_spec.rb`), then implement both Value Objects (`[REQ-SOC-001]`, `[REQ-DISC-001]`).</step>
  <step id="2" status="complete">Write failing RSpec model & policy tests for `Friendship` and `FriendshipPolicy` (`spec/models/friendship_spec.rb`, `spec/policies/friendship_policy_spec.rb`) covering unordered pair uniqueness, self-friendship prevention, 20-pending outgoing limit, `accept!`, and `UserBlock` cleanup hook integration, then implement the migration, model, policy, and cleanup hook (`[REQ-SOC-001]`, `[REQ-BLOCK-001]`, `[REQ-BLOCK-002]`).</step>
  <step id="3" status="complete">Write failing RSpec request tests for Anti-Stalking `@username` Search and Profile Friendship Status (`spec/requests/api/v1/users_search_spec.rb`), verifying blocked/discarded exclusion and zero wishlist/email leakage, then implement `GET /api/v1/users/search` and `friendship_status_for` in `Api::V1::UsersController` (`[REQ-SOC-001]`, `[REQ-WISH-001]`, `[REQ-BLOCK-001]`).</step>
  <step id="4" status="complete">Write failing RSpec request tests for `Api::V1::FriendshipsController` (`spec/requests/api/v1/friendships_spec.rb`) covering listing friends/requests, sending requests, accepting, declining/removing, and block enforcement, then implement `Api::V1::FriendshipsController` and routes (`[REQ-SOC-001]`, `[REQ-BLOCK-001]`).</step>
  <step id="5" status="pending">Write failing RSpec model, policy, and request tests for `Report`, `ReportPolicy`, and `Api::V1::ReportsController` (`spec/models/report_spec.rb`, `spec/requests/api/v1/reports_spec.rb`), then implement the `reports` migration, `Report` model, `ReportPolicy`, `Api::V1::ReportsController`, and `AuditEvent` logging (`[REQ-SOC-001]`, `[REQ-DISC-001]`, `[REQ-ADM-001]`).</step>
</implementation_plan>
