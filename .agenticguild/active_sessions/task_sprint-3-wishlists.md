<task_session>
  <metadata>
    <task_name>MVP Sprint 3 — Wishlists (Anti-Stalking Privacy + Secret Links)</task_name>
    <type>Feature</type>
    <req_id>REQ-WISH-001, REQ-WISH-002, REQ-WISH-003, REQ-WISH-004, REQ-WISH-005, REQ-WISH-006, REQ-LIFE-001 (wishlist cascade), REQ-ARCH-002 (wishlist schema readiness), REQ-BLOCK-001/002 (shares), REQ-AUTH-001 (web return_to)</req_id>
    <roadmap_item>MVP Sprint 3 — Wishlists (Anti-Stalking Privacy + Secret Links)</roadmap_item>
  </metadata>

  <implementation_plan>
    <!-- Filled in explore-task Phase 1 Step 1.4 after Final check + lock checklist. Do not start-task until owner authorizes. -->
  </implementation_plan>

  <working_notes>
## Base
- Repo: jotadugarte/wish-list-community
- origin/main @ 8dd403c (Merge #8 signup P0) — agentic:guild 1.1.0
- Pre-Sprint 3 locked review: docs/roadmap-pre-sprint3-review.md (Project store) + `.agenticguild/active_sessions/task_roadmap-pre-sprint3-review.md`
- Explore skill: no product code; no implementation branch/PR from this skill

## Opening triad (2026-11-26)

### What we know
- Signup P0 merged (#8); Flutter SignUpScreen + `POST /api/v1/signup` exist.
- No `Wishlist` / `WishlistShare` models, tables, API routes, or Flutter screens yet. SoftDeletable + UserBlock cleanup registries exist (shares hook not registered).
- Hotwire stack already present (Turbo + Stimulus + Tailwind); web `SessionsController` exists but has **no HTML login/signup**, no `return_to`, redirects to `root` (health).
- SPEC visibility matrix (4 actors) + REQ-WISH-001..006 are authoritative; onda 2 removed public Discover for personal lists.
- Ñata OG copy locked in design refs: preview = invitation *"Lista de deseos de @usuario"* — no private items to bots.
- Pre-Sprint 3 owner locks: **D3a** wishlists S3 / items S4; **D4a** Hotwire mínimo `/s/:share_token` + OG-safe + return_to in S3; **D6a** API+Flutter primary, web only where SPEC requires (Secret Link); **D2b** DesignTokens defaults until Ñata HTML.

### What we don't know (owner forks)
- Exact web auth HTML surface for `return_to` across login **and** sign-up (REQ-WISH-005) — see Open **O1**.
- Default `privacy_mode` on create — see Open **O2**.
- How friends discover another friend's accessible wishlists in API — see Open **O3**.
- Whether owner can **rotate** `share_token` while staying in `shared` — see Open **O4**.

### What we need to define (before start-task)
- Answer O1–O4 (or defer with parking notes).
- Domain model + API surface + Flutter screens list for S3-only scope (empty wishlist shells; no Item CRUD).
- Soft-delete / block cleanup hooks that are safe before Items/Reservations exist.
- Final check + `<implementation_plan>` (TDD), then handoff to start-task only when owner says so.

## Classification
**Feature** (new domain entities + API + Flutter + minimal Hotwire Secret Link).

## Locked (from SPEC + pre-Sprint 3 + design)

| ID | Decision | Source |
| :--- | :--- | :--- |
| **L-D3a** | Wishlists = Sprint 3; Items = Sprint 4. S3 delivers empty wishlist shells (no Item CRUD, no reserve/gift). | pre-Sprint 3 D3a |
| **L-D4a** | Hotwire mínimo for `GET /s/:share_token` + OG-safe meta + `return_to` across web auth in Sprint 3 (**obligatory**). | pre-Sprint 3 D4a / REQ-WISH-005 |
| **L-D6a** | Primary client = `/api/v1` + Flutter. Web UI only for Secret Link (and the minimal web auth needed for return_to). **No** full web wishlist CRUD in S3. | pre-Sprint 3 D6a |
| **L-D2b** | Flutter uses DesignTokens defaults; Ñata HTML retoken later (non-blocking). | pre-Sprint 3 D2b |
| **L-modes** | Personal wishlist privacy modes are only `friends` and `shared` (no public Discover for personal lists). | SPEC REQ-WISH-001 + onda 2 |
| **L-friends** | `friends`: all accepted friends can view; strangers searching `@username` never see personal lists. | SPEC matrix / REQ-WISH-001 |
| **L-shared** | `shared`: selected friends via `WishlistShare` + anyone with valid Secret Link (`share_token`). | SPEC 4.3 / REQ-WISH-001 |
| **L-token-wipe** | Switching `shared` → `friends` sets `share_token = nil` and revokes secret-link-derived `WishlistShare`s. | SPEC / DATA_FLOW_MAP |
| **L-shared-with-me** | Logged-in non-blocked user opening valid Secret Link persists `WishlistShare(source: secret_link)` while token remains valid. | REQ-WISH-003 |
| **L-urls** | Immutable URLs: `/wishlists/:id` (API/resource id) and `/s/:share_token` — independent of `@username`. | REQ-WISH-006 |
| **L-og** | Unauthenticated OG / WhatsApp card: invitation *"Lista de deseos de @username"* — **never** item titles, images, or counts. | Ñata design + REQ-WISH-005 |
| **L-block** | Block Wins denies Secret Link and all wishlist access either direction; block cleanup must delete `WishlistShare`s between the pair. | REQ-BLOCK-001/002 |
| **L-schema-ready** | Wishlist schema includes optional `event_date`, nullable `activity_id` readiness (REQ-ARCH-002), SoftDeletable `discarded_at`, and `max_reservations_per_user` column (default `nil`) even though reservation **UI/logic** waits for Sprint 5. | SPEC 4.3 / REQ-ARCH-002 / REQ-WISH-004 |
| **L-guest-reserve** | Guests may view Secret Link preview; must log in to reserve/gift — reserve itself is Sprint 5 (no items in S3). | REQ-WISH-002 + D3a |
| **L-process** | TDD (`verification: tdd`); start-task hands-off when owner authorizes; no start-task until explicit owner order. | config + pre-Sprint 3 |

## Open (decision cards for owner)

### O1 — Web auth HTML for Secret Link `return_to` (REQ-WISH-005)
**Context:** `/s/:share_token` is web Hotwire. Unauthenticated humans and crawlers hit it. After viewing the safe invitation, a guest must log in or sign up and land back on the same Secret Link. Today web `SessionsController` only `create`/`destroy` with no HTML forms and always redirects to health `root`. API signup exists; web signup does not.

**Option A — Minimal Hotwire login + signup with `return_to` (recommended):** Add thin HTML `new` (and create redirects) for web session + web signup (or reuse signup domain rules), validate `return_to` is a same-origin path under `/s/...`, restore after auth, then register Shared-with-me. Cost: small web surface in S3. Unlocks: full REQ-WISH-005 compliance and WhatsApp → browser → account → list flow.

**Option B — Web login only; signup Flutter-only:** Guests without accounts cannot complete the link on web. Cost: lower web work. Breaks SPEC wording ("login/sign-up") for the primary Secret Link surface.

**Option C — Defer return_to / treat as risk:** Ship OG + page without round-trip restore. Cost: lowest now. Leaves REQ-WISH-005 incomplete and a broken guest funnel.

**Recommendation:** **A**. Reply `O1A` / `O1B` / `O1C` (or free-form).

### O2 — Default `privacy_mode` on create
**Context:** Owner creates a wishlist before choosing audience.

**Option A — Default `friends` (recommended):** Safer; no `share_token` until owner switches to `shared` (or explicitly enables Secret Link). Matches anti-stalking posture.

**Option B — Default `shared`:** Generate `share_token` immediately; easier "copy link" UX but wider accidental exposure if owner forgets.

**Recommendation:** **A**. Reply `O2A` / `O2B`.

### O3 — Friend discovery of accessible wishlists
**Context:** Accepted friends must be able to open `friends`-mode lists (and lists they are explicitly shared into). Profile search today never embeds wishlists (anti-stalking for strangers). Friends need a discovery path in Flutter.

**Option A — Nested index (recommended):** `GET /api/v1/users/:username/wishlists` policy-scoped to wishlists the viewer may see (empty for strangers → 404/empty per anti-stalking rules aligned with profile). Keeps `GET /users/:username` card thin.

**Option B — Embed wishlists on friend profile payload:** Only when `friendship_status=accepted`. Cost: couples profile to wishlist serialization; harder to paginate later.

**Option C — No friend index in S3; only "mine" + "Shared with me":** Friends cannot browse a friend's `friends`-mode lists until a later sprint — **violates** SPEC matrix row 2 for Sprint 3 privacy goals.

**Recommendation:** **A**. Reply `O3A` / `O3B` / `O3C`.

### O4 — Rotate Secret Link while staying in `shared`
**Context:** SPEC mandates wipe on `shared`→`friends`. WhatsApp leak / accidental forward may need a new token without flipping mode.

**Option A — Explicit regenerate (recommended):** Owner action regenerates `share_token`, invalidates old URL, revokes `source: secret_link` shares (explicit friend shares stay). AuditEvent.

**Option B — Mode flip only:** Must switch to `friends` then back to `shared` to mint a new token. Cost: simpler API; worse UX; easy to forget re-adding selected friends.

**Recommendation:** **A**. Reply `O4A` / `O4B`.

## Deferred (parked — out of Sprint 3 product scope)

| Item | Parking note |
| :--- | :--- |
| Item CRUD / media / OG store extract | Sprint 4 (D3a) |
| Reservations / grace / limits enforcement UI | Sprint 5 (column may exist; no reserve endpoints) |
| Gift fulfillment / thank-you | Sprint 6 |
| Wishlist abuse reports + mutation rate limits expansion | Sprint 7 (`Report` already polymorphic-ready) |
| Notifications foundation | D5a before/with Sprint 5 |
| Universal / App Links for `/s/:token` | Sprint 9 (`REQ-MOB-001`) |
| Public Discover for personal lists | Removed by onda 2; do not reintroduce without ADR |
| Full web wishlist CRUD / admin | Not S3 (D6a); Admin later |
| Ñata visual retoken | D2b when HTML arrives |
| Soft-delete cascade **to Items + cancel Reservations** | Register wishlist hooks in S3; Item/Reservation bodies fill in S4/S5 |
| User account soft-delete cascading wishlists | Wire when Wishlist exists; verify in S3 tests as far as wishlist-only |

## Implementation risks (not owner forks)

| Risk | Mitigation |
| :--- | :--- |
| Empty shells look "unfinished" in Flutter | Explicit empty states: "Sin ítems aún" / owner CTA deferred until S4 copy; document in QA as expected |
| `activity_id` without `activities` table | Nullable bigint **without** FK until Activities sprint; document in migration comment |
| Web session currently non-HTML | O1A implies adding views + `new` routes; system specs for return_to |
| Pundit Scope for wishlists | Policy::Scope must encode friends / explicit share / secret_link / owner; strangers get none |
| Guest "view wishlist" vs OG | Unauthenticated humans see invitation + CTAs only; item payload never in OG; full shell after auth (still empty in S3) |
| `share_token` entropy | URL-safe random (e.g. 32 bytes) unique indexed; never sequential ids |
| Block cleanup Zeitwerk | Register `WishlistShare` hook and reference constant in `UserBlock.execute_cleanup_hooks!` pattern like Friendship |

## Domain Model (CbC draft)

### Entity: `Wishlist`
- **Responsibility:** Owned collection of desired items (items themselves in S4) with anti-stalking privacy and optional event date.
- **Invariants:**
  - Belongs to one `User` owner; URLs use immutable id / `share_token`, never `@username`.
  - `privacy_mode ∈ {friends, shared}`.
  - `share_token` present only when `privacy_mode == shared`; nil when `friends`.
  - Soft-deletable; restore within grace does not resurrect canceled reservations (S5+).
  - `event_date` optional; timezone interpretation uses owner/`User.time_zone` where relevant later.
- **Value Objects / branded types:** `ShareToken` (opaque URL-safe string); consider `PrivacyMode` enum VO.

### Entity: `WishlistShare`
- **Responsibility:** Grants a specific user durable access to a wishlist (`explicit` selected friend, or `secret_link` after opening a valid token).
- **Invariants:**
  - Unique `(wishlist_id, user_id)` (or equivalent).
  - `source ∈ {explicit, secret_link}`.
  - Deleted on Block Wins between the pair; secret_link rows revoked when token wiped/rotated.
  - Opening Secret Link while logged in upserts `source: secret_link` while token valid.
- **Value Objects:** none beyond `source` enum.

### Supporting (existing)
- `User`, `Friendship`, `UserBlock`, `SoftDeletable`, `AuditEvent`, `ApplicationPolicy` — extend; do not reinvent Block Wins.

### Out of S3 domain creation
- `Item`, `ItemLink`, `Reservation`, `GiftRecord` — Sprint 4+.

## Proposed S3 API surface (draft — refine after O1–O4)
- `GET/POST /api/v1/wishlists` — mine (index/create)
- `GET/PATCH/DELETE /api/v1/wishlists/:id` — show/update/soft-delete (restore endpoint TBD if needed in S3)
- `POST /api/v1/wishlists/:id/shares` / `DELETE ...` — manage explicit friend shares when `shared`
- `POST /api/v1/wishlists/:id/share_token/rotate` — if O4A
- `GET /api/v1/shared_wishlists` — "Shared with me"
- `GET /api/v1/users/:username/wishlists` — if O3A
- Web: `GET /s/:share_token` (Hotwire + OG); web auth with `return_to` per O1

## Proposed Flutter surfaces (draft)
- My wishlists list + create/edit privacy/event_date + copy Secret Link when shared
- Shared with me tab/list
- Friend wishlists list (from O3) + wishlist detail empty shell
- DesignTokens defaults (D2b); bilingual AppStrings

## Repo facts (main @ 8dd403c)
- No wishlist files under `backend/` or `mobile/`.
- `API_CONTRACT.md` has zero wishlist endpoints yet (docs update belongs in start-task / sync-docs).
- `BEHAVIOUR_MATRIX.md` missing — offer at lock-checklist (step 1.4), not now.
  </working_notes>
</task_session>
