# Project Roadmap

Things done and things left to do. Update this when finishing branches; use `roadmap-manage` to add, prioritize, or catalog items.

**Format:** Use `[x]` for done, `[ ]` for pending. Add `(REQ-ID)` to link to SPEC. Add `— YYYY-MM-DD` for done date. Add `— Branch: name` for in-progress. Add `— Depends on: Item` for dependencies.

---

## Technical decisions
- **Monorepo structure**: `backend/` (Ruby on Rails 8 + PostgreSQL + Solid Queue + Hotwire + Tailwind CSS + Pundit + RSpec) and `mobile/` (Flutter iOS + Android consuming `/api/v1`)
- **JS policy**: Hotwire (Turbo + Stimulus via `importmap`) only; no heavy frontend SPA frameworks
- **Server authority**: 100% of business logic, permissions, anti-stalking privacy, and reservation rules live on the server; Web and Flutter are clients
- **Authentication security**: Web uses CSRF-protected cookie sessions; `/api/v1` uses a dedicated `api_tokens` table storing only SHA-256 `token_digest` (never raw tokens in DB), with FCM `device_token` unbinding on logout
- **Admin panel**: Web only (Rails), backed by an immutable `audit_events` table

## Done
- [x] **MVP Sprint 1 (Backend Foundation) — Base + Auth + API + Core Policies** — 2026-11-24
  - [x] Monorepo setup: `backend/` (Rails 8 + PostgreSQL + Solid Queue + Hotwire/Tailwind CSS + RSpec + Pundit) and `mobile/` skeleton (`REQ-ARCH-001`) — 2026-11-24
  - [x] Versioned API `/api/v1` with SHA-256 `api_tokens` authentication and `RecordNotUnique` idempotency handling; web uses cookie sessions (`REQ-AUTH-001`, `REQ-ARCH-003`) — 2026-11-24
  - [x] Authentication (`POST /api/v1/signup` with `terms_accepted_at`, login, logout, sessions), anti-enumeration password reset (always generic `200 OK`), and Rails 8 `rate_limit` on auth endpoints (`REQ-AUTH-001`, `REQ-AUTH-002`, `REQ-AUTH-003`) — 2026-11-24; signup API wired 2026-11-26 (`cursor/chore-signup-p0`)
  - [x] Public profile: unique `@username` (email stays strictly private), 30-day change cooldown + 30-day quarantine on previous `@username`, preferred `locale` (`es`/`en`), and `time_zone` (`REQ-USER-001`, `REQ-USER-002`, `REQ-USER-003`, `REQ-USER-004`) — 2026-11-24
  - [x] Central Pundit permissions layer (*default-deny*) + Block users ("block wins": immediately cuts access and transactionally destroys friendship, shares, and active reservations) + immutable `AuditEvent` foundation (`REQ-BLOCK-001`, `REQ-BLOCK-002`, `REQ-ADM-001`) — 2026-11-24
  - [x] Soft-delete + restore infrastructure (`SoftDeletable` concern + 30-day account restoration window before PII purge) (`REQ-LIFE-001`, `REQ-LIFE-002`) — 2026-11-24 — *Wishlist cascade Done in Sprint 3; item cascade Done in Sprint 4; reservation cascade Done in Sprint 5*
- [x] **MVP Sprint 2 (Backend) — Social & Anti-Stalking Profile Search** — 2026-11-25
  - [x] Search users by `@username` via `SearchQuery` Value Object (`GET /api/v1/users/search` and `GET /api/v1/users/:username`, anti-stalking: non-friends only see `@username` and `friendship_status`, never personal wishlists or `email_address`, with batched zero-`N+1` status loading) (`REQ-SOC-001`, `REQ-WISH-001`, `REQ-BLOCK-001`) — 2026-11-25
  - [x] Friend requests + accept/decline/remove + friends list (`Friendship` & `FriendshipPolicy`, enforced by unordered unique pair index in PostgreSQL, 20-pending outgoing anti-spam cap, and automatic `UserBlock` cleanup hook) (`REQ-SOC-001`, `REQ-BLOCK-001`, `REQ-BLOCK-002`, `REQ-ADM-001`) — 2026-11-25
  - [x] Report user (`Report` polymorphic model, `ReportReason` Value Object, `ReportPolicy`, `POST /api/v1/reports` queue, duplicate pending report prevention, and immutable `AuditEvent` logging) (`REQ-SOC-001`, `REQ-DISC-001`, `REQ-ADM-001`) — 2026-11-25
- [x] **MVP Sprint 1 (Mobile Foundation) — Flutter Base + Design System** — 2026-11-26 — Branch: `feat/sprint-1-2-mobile-foundation`
  - [x] Flutter project + parameterized `DesignTokens` / `AppTheme` / `AppIconBadge` / `AppNavigationShell` + Dart domain VOs + `ApiClient` / secure token storage + `AuthRepository` + auth UI (`LoginScreen`, `SignUpScreen`, `PasswordResetScreen`, `AccountRestoreScreen`, `ProfileSettingsScreen`) with bilingual `AppStrings` (`REQ-ARCH-001`, `REQ-AUTH-001`, `REQ-AUTH-002`, `REQ-AUTH-003`, `REQ-LIFE-002`, `REQ-USER-001`, `REQ-USER-002`) — 2026-11-26; `SignUpScreen` added 2026-11-26 (`cursor/chore-signup-p0`)
- [x] **MVP Sprint 2 (Mobile) — Social & Anti-Stalking Profile Search (Flutter Screens)** — 2026-11-26 — Branch: `feat/sprint-1-2-mobile-foundation`
  - [x] Flutter screens for `@username` search, friend requests/list, block/report consuming `/api/v1/users/search`, `/api/v1/friendships`, `/api/v1/user_blocks`, and `/api/v1/reports` (`REQ-SOC-001`, `REQ-WISH-001`, `REQ-BLOCK-001`, `REQ-DISC-001`) — 2026-11-26
- [x] **Chore P0 — Signup (before Sprint 3)** — 2026-11-26 — Branch: `cursor/chore-signup-p0`
  - [x] Registration `POST /api/v1/signup` creating users with required `terms_accepted_at` + Rails 8 `rate_limit` (`REQ-AUTH-001`, `REQ-AUTH-002`, `REQ-AUTH-003`)
  - [x] Flutter `SignUpScreen` + `AuthRepository.signUp` consuming signup API (`REQ-AUTH-001`, `REQ-AUTH-002`)
  - [x] `API_CONTRACT` / ROADMAP / testing docs updated for signup Done

- [x] **MVP Sprint 3 — Wishlists (Anti-Stalking Privacy + Secret Links)** — 2026-11-26 — Branch: `cursor/feat-sprint-3-wishlists`
  - [x] Wishlist CRUD with optional `event_date`, immutable URLs (`/wishlists/:id` and `/s/:share_token` independent of `@username`), and v1-ready nullable `activity_id` (`REQ-WISH-004`, `REQ-WISH-006`, `REQ-ARCH-002`) — 2026-11-26
  - [x] Soft-delete/restore for wishlists via `SoftDeletable` (item cascade Done in Sprint 4; reservation cascade Done in Sprint 5) (`REQ-LIFE-001`) — 2026-11-26
  - [x] Anti-stalking privacy per personal wishlist (`REQ-WISH-001`, `REQ-WISH-002`, `REQ-WISH-003`):
    - [x] `friends`: visible to accepted friends only (never exposed to strangers searching `@username`)
    - [x] `shared`: visible to specific selected friends + anyone opening the Secret Link (`share_token`)
  - [x] Secret link lifecycle: invalidated on `friends`; OG invitation without items; `return_to` login/signup; Shared-with-me upsert; token rotate (O4A) (`REQ-WISH-002`, `REQ-WISH-003`, `REQ-WISH-005`, `REQ-WISH-006`) — 2026-11-26
  - [x] Guests view Secret Link invitation only; must log in for Shared-with-me (reserve Done in Sprint 5; gift remains Sprint 6) (`REQ-WISH-001`, `REQ-WISH-002`) — 2026-11-26
  - [x] API v1 endpoints + Flutter wishlist screens for this sprint — 2026-11-26
- [x] **MVP Sprint 4 — Items + Media + Automatic Store Image Extraction** — 2026-11-26 — Branch: `cursor/feat-sprint-4-items-media-ab93`
  - [x] Item CRUD (`1 item = 1 unit`), prominent `specifications` note below the image (for exact color/size/variant clarifications), `priority` desire levels (`low`, `medium`, `high`, `must_have`), multiple `http/https` purchase links (`ItemLink`), and v1-ready nullable `price_cents`/`currency` (`REQ-ITEM-001`, `REQ-ITEM-003`, `REQ-ITEM-005`, `REQ-ARCH-002`) — 2026-11-26
  - [x] Soft-delete/restore cascade for items (no ghost reservations on restore) via `SoftDeletable` hooks (`REQ-LIFE-001`) — 2026-11-26
  - [x] Automatic best-effort extraction of product image and title (`og:image`, `og:title` with SSRF protection; confirm-before-persist) when pasting or sharing a store link (`REQ-ITEM-006`) — 2026-11-26
  - [x] Up to 3 images per item (`REQ-ITEM-002`):
    - [x] Max 2MB each, max 1600px on the longest side
    - [x] Optional client-side compression (UX) — shipped Sprint 9 (O5A)
    - [x] Mandatory server-side resize + WebP re-encode + full EXIF/GPS metadata stripping via `libvips`
  - [x] API v1 endpoints + Flutter screens for this sprint — 2026-11-26
- [x] **MVP Sprint 5 — Secret Reservations (72h Grace Auto-Release & Context-Aware Limits)** — 2026-11-26 — Branch: `cursor/feat-sprint-5-secret-reservations-47be` — Draft PR #12
  - [x] Reserve an item (logged-in users with access only) with "first to reserve wins" concurrency enforced by a PostgreSQL partial unique index (`WHERE status IN ('active', 'expired_grace')`) (`REQ-RES-001`) — 2026-11-26
  - [x] Zero spoilers for recipient: owner never sees reservation state, and reservation mutations never update `items.updated_at`; viewer-relative `availability` for non-owners (O3A) (`REQ-RES-002`) — 2026-11-26
  - [x] Context-aware reservation limits: personal wishlists default to unlimited per friend (or owner-configurable `max_reservations_per_user`); group activities default to 1 per participant deferred to v1 (`REQ-RES-005`) — 2026-11-26
  - [x] Private note and timezone-aware private `estimated_date` from the reserver (`REQ-RES-001`, `REQ-USER-003`) — 2026-11-26
  - [x] 72-hour expiration grace window via `ReservationGraceSweepJob`: extend or voluntary cancel in Sprint 5; mark purchased deferred to Sprint 6 (O2A/O5A/O6A/O7A) (`REQ-RES-006`) — 2026-11-26
  - [x] Dedicated *"My Reservations"* screen/endpoint (`/api/v1/my_reservations`) + notification to reserver if owner edits critical details or deletes a reserved item (`REQ-RES-003`, `REQ-RES-004`) — 2026-11-26
  - [x] Notification foundation: in-app + email enqueue + push no-op; preferences defaults-on (O1A/O8A) (`REQ-NOTIF-001`) — 2026-11-26
  - [x] Hotwire Secret Link reserve/extend/cancel parity with Flutter (O4B) (`REQ-WISH-002`, `REQ-RES-001`) — 2026-11-26
  - [x] API v1 endpoints + Flutter screens for this sprint — 2026-11-26
  - [x] **MVP Sprint 6 — Dual-Path Gift Fulfillment + Anonymous Thank-You Note** — Draft PR #13 — 2026-11-26
  - [x] Unified `"Reserved / Unavailable"` status shown to other friends for both reserved and secretly purchased items; third-party friends cannot override another friend's active reservation (`REQ-GIFT-002`) — 2026-11-26
  - [x] Dual-path fulfillment (`REQ-GIFT-001`, `REQ-GIFT-003`):
    - [x] Path 1 (Gifter-initiated): Reserver marks `purchased_secret` (hidden from owner) -> marks `delivered_pending_confirmation` (sends anonymous prompt to owner) -> owner confirms `received_confirmed` — 2026-11-26
    - [x] Path 2 (Owner 1-step): Owner directly marks any item as `received_confirmed` in 1 step (closing any active reservation and notifying the reserver) — 2026-11-26
  - [x] Visual separation of `received_confirmed` items into a *"Received Gifts"* section at the bottom of the wishlist (`REQ-ITEM-004`) — 2026-11-26
  - [x] Optional anonymous *"Thank You"* note from owner upon confirming receipt, delivered privately to the gifter without revealing the gifter's identity (`REQ-GIFT-004`) — 2026-11-26
  - [x] Store reference to the purchase link used for an online gift (visible to admin audit only) (`REQ-ADM-001`) — 2026-11-26
  - [x] API v1 endpoints + Flutter screens for this sprint (Hotwire Secret Link gift parity O3C included) — 2026-11-26
- [x] **MVP Sprint 7 — Anti-Spam, Rate Limits & Wishlist Reports** — 2026-11-26 — Branch: `cursor/feat-sprint-7-anti-spam-72e9` — Draft PR #14
  - [x] Rails 8 `rate_limit` anti-spam protection across mutation and report endpoints + report wishlist (`REQ-DISC-001`) — 2026-11-26
  - [x] Sensitive content handled through reports queue (`REQ-DISC-001`) — 2026-11-26
  - [x] API v1 endpoints + Flutter screens for this sprint (Hotwire Secret Link Reportar lista parity included) — 2026-11-26
- [x] **MVP Sprint 8 — Admin/Moderation (Web Only)** — 2026-11-27 — Branch: `cursor/sprint-8-admin-moderation-f6bf` — Draft PR #15
  - [x] Admin panel: report queue + moderation actions (dismiss / suspend / soft-delete) (`REQ-ADM-001`) — 2026-11-27
  - [x] Admin audit log viewer (`AuditEvent` history) with 1-click revert for suspend / admin soft-delete / dismiss→pending (`REQ-ADM-001`) — 2026-11-27
  - [x] Admin auditing of gifter identity and online gift purchase link (`REQ-ADM-001`) — 2026-11-27
- [x] **MVP Sprint 9 — Mobile Wrap-Up & Native "Share to App" Sheet** — 2026-11-27 — Branch: `cursor/sprint-9-mobile-wrap-up-5dfd` — PR #16
  - [x] Absorbed **Notifications (MVP)** (O1A): FCM adapter + Flutter register/unbind, prefs + inbox on Flutter and Hotwire, full event catalog (`REQ-NOTIF-001`, `REQ-NOTIF-002`) — 2026-11-27
  - [x] Member Hotwire `/app` parity (O2B/O12A); public `/terms` `/privacy` (O8A/O13A) — 2026-11-27
  - [x] Share-to-App + deep links friend/secret only (O3A/O4B); client image compress (O5A) (`REQ-MOB-001`, `REQ-MOB-002`, `REQ-ITEM-002`) — 2026-11-27
  - Ops risks remaining (do not block Done): staging→prod host swap (O9B), Google FCM keys (O10B), owner legal-text approval before store submit (O8A); owner device QA deferred (Share sheet, App Links, live FCM, browser Hotwire walk)
- [x] **Backlog — Admin Brand / Style Guide (Web Admin dual preview)** — 2026-11-27 — Branch: `cursor/admin-brand-style-guide-ea18` — PR #17
  - [x] Admin-only Hotwire `GET /admin/style_guide`: web preview + HTML/CSS phone mock from shared `design/design_tokens.json` (not Flutter Web); tokens table, es/en + light/dark, version stamp, print CSS; Flutter `SharedDesignTokenCatalog` additive reader (`REQ-ARCH-001`, `REQ-ADM-001`) — 2026-11-27
  - Follow-up: retokenize shared file when Ñata final visual HTML lands; owner browser print/PDF + phone-mock vs Flutter visual check

## In Progress
_(none)_

## Pending (by priority)
_(none — next product work is v1 Activities in Backlog)_

## Backlog
- [ ] **v1 Sprint A — Activities (Configurable System + Exclusions + Blind Dropout Bridge)**
  - [ ] Create a group activity (owner, name, dates, single currency, external activity link scoped strictly to that activity's info) (`REQ-ACT-001`)
  - [ ] 5 configurable budget modes per activity (`budget_mode`: `none`, `fixed`, `min_only`, `max_only`, `range`) (`REQ-ACT-005`)
  - [ ] Settings when creating an activity (`REQ-ACT-001`):
    - [ ] `assignment_mode`: `secret_santa` (1->1) / `open_gifting` (everyone to everyone)
    - [ ] `visibility_mode`: `recipient_only` / `all_participants`
    - [ ] `reservation_visibility`: `hidden_from_recipient` / `visible_to_recipient`
  - [ ] Invite friends / accept participants (blocks prevent participation; minimum 3 `accepted` participants required to draw) (`REQ-ACT-001`)
  - [ ] Pair Exclusions (`ActivityExclusion`: Participant A cannot draw Participant B) with bounded deterministic solvability validation and single Hamiltonian cycle draw (`REQ-ACT-002`, `REQ-ACT-004`)
  - [ ] Post-draw participant dropout recovery: creator chooses between **Blind Auto-Bridge** (server bridges `A -> C` without ever revealing to the creator who gifts whom) or **Full Redraw** (`REQ-ACT-003`, `REQ-ACT-004`)
- [ ] **v1 Sprint B — Activities (Lists + Reservations + Budget Enforcement)**
  - [ ] Each user adds their activity items (manual price + currency) (`REQ-ACT-005`)
  - [ ] Reservations within an activity (default 1 active reservation per participant in `secret_santa`; configurable in `open_gifting`) (`REQ-RES-005`)
  - [ ] Budget validation enforcing the activity's chosen `budget_mode` (`fixed`, `min_only`, `max_only`, `range`) (`REQ-ACT-005`)
- [ ] **v1 — Group Co-Gifting ("Cooperacha")**
  - [ ] Allow a reserver of an expensive item to invite 1 or more friends to chip in and share that reservation
- [ ] **v1 — Email confirmation**
- [ ] **Backlog v1 — Activities: "don't repeat last year's gift" (optional)**
- [ ] **Backlog — Validate price against link (best-effort)**
