<task_session>
  <metadata>
    <task_name>MVP Sprint 3 — Wishlists (Anti-Stalking Privacy + Secret Links)</task_name>
    <type>Feature</type>
    <req_id>REQ-WISH-001, REQ-WISH-002, REQ-WISH-003, REQ-WISH-004, REQ-WISH-005, REQ-WISH-006, REQ-LIFE-001 (wishlist cascade), REQ-ARCH-002 (wishlist schema readiness), REQ-BLOCK-001/002 (shares), REQ-AUTH-001 (web return_to)</req_id>
    <roadmap_item>MVP Sprint 3 — Wishlists (Anti-Stalking Privacy + Secret Links)</roadmap_item>
  </metadata>

  <implementation_plan>
    <step id="1" status="pending">Write failing RSpec model/VO specs for `Wishlist` + `ShareToken`/`PrivacyMode`: defaults (`privacy_mode=friends`, `share_token` nil), `shared` mints unique URL-safe token, `shared`→`friends` wipes token, SoftDeletable discard/restore within grace, optional `event_date`, nullable `activity_id` + `max_reservations_per_user` columns present. Trace `[REQ-WISH-001]`, `[REQ-WISH-002]`, `[REQ-WISH-004]`, `[REQ-WISH-006]`, `[REQ-ARCH-002]`, `[REQ-LIFE-001]`.</step>
    <step id="2" status="pending">Implement migrations + models minimally to make step 1 green (`wishlists`, `wishlist_shares` with unique `(wishlist_id, user_id)`, indexes on `share_token` unique where present, SoftDeletable on Wishlist). No controllers yet.</step>
    <step id="3" status="pending">Write failing RSpec for `WishlistShare` invariants + `UserBlock` cleanup hook deleting shares between the pair; friendship `remove!` also deletes shares between the pair (S3 risk mitigation). Trace `[REQ-WISH-003]`, `[REQ-BLOCK-002]`.</step>
    <step id="4" status="pending">Implement `WishlistShare` + register cleanup hooks (Zeitwerk-safe constant reference) until step 3 green.</step>
    <step id="5" status="pending">Write failing `WishlistPolicy` / Scope specs for the 4-actor matrix (stranger, accepted friend on `friends`/`shared`+explicit, secret_link share, blocked either direction) plus owner. Trace `[REQ-WISH-001]`, `[REQ-BLOCK-001]`.</step>
    <step id="6" status="pending">Implement `WishlistPolicy` (+ Scope) until step 5 green. Default-deny via ApplicationPolicy.</step>
    <step id="7" status="pending">Write failing request specs for owner CRUD: `GET/POST /api/v1/wishlists`, `GET/PATCH/DELETE /api/v1/wishlists/:id` (soft-delete), optional `POST .../restore`; privacy mode transitions; rotate `POST /api/v1/wishlists/:id/share_token/rotate` (O4A); explicit shares `POST/DELETE .../shares`. Trace `[REQ-WISH-001..004]`, `[REQ-WISH-006]`, `[REQ-LIFE-001]`, `[REQ-ARCH-003]`.</step>
    <step id="8" status="pending">Implement API controllers/routes/serializers for step 7 until green (thin controllers; services for mode change, rotate, share upsert).</step>
    <step id="9" status="pending">Write failing request specs for `GET /api/v1/shared_wishlists` and `GET /api/v1/users/:username/wishlists` (O3A): strangers get empty/404 aligned with anti-stalking; friends see accessible lists; block → 404. Trace `[REQ-WISH-001]`, `[REQ-WISH-003]`, `[REQ-BLOCK-001]`.</step>
    <step id="10" status="pending">Implement shared-with-me + user wishlists index until step 9 green.</step>
    <step id="11" status="pending">Write failing system/request specs for Hotwire `GET /s/:share_token`: OG meta invitation only (`Lista de deseos de @username`, no items); guest HTML invitation + login/signup CTAs with `return_to`; logged-in non-blocked upserts `WishlistShare(source: secret_link)` and shows empty shell; invalid/blocked/discarded → 404; open-redirect rejected. Trace `[REQ-WISH-002]`, `[REQ-WISH-003]`, `[REQ-WISH-005]`, `[REQ-WISH-006]`.</step>
    <step id="12" status="pending">Implement Secret Link controller/view + safe OG helpers until step 11 green (no item payloads).</step>
    <step id="13" status="pending">Write failing system specs for web Hotwire login + signup HTML with `return_to` allowlisted to same-origin `/s/...` paths; after auth redirect back and register Shared-with-me. Reuse signup domain rules (`terms_accepted_at`, rate_limit). Trace `[REQ-WISH-005]`, `[REQ-AUTH-001]`, `[REQ-AUTH-002]`, `[REQ-AUTH-003]`.</step>
    <step id="14" status="pending">Implement web session `new` + web signup HTML/controllers and `return_to` plumbing until step 13 green (O1A).</step>
    <step id="15" status="pending">Write failing Flutter widget/repository tests for: my wishlists list/create/edit (default `friends` O2A), Shared with me, friend wishlists via username endpoint, wishlist detail empty shell, copy/rotate Secret Link when `shared`, bilingual AppStrings, DesignTokens defaults. Trace matching REQ-WISH-*.</step>
    <step id="16" status="pending">Implement Flutter screens/repos/navigation until step 15 green (D2b / D6a). No Item UI.</step>
    <step id="17" status="pending">Update living docs in-repo as part of the feature work: `docs/core/API_CONTRACT.md` wishlist endpoints; ROADMAP Sprint 3 checkboxes only when verified; touch DATA_FLOW_MAP only if share/unfriend hook wording needs the friendship-remove note. Keep architecture anchors intact (no ADR unless violated).</step>
    <step id="18" status="pending">Run full backend RSpec + `flutter analyze`/`flutter test` locally; fix failures until green. End of start-task implementation scope.</step>
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
- None material — O1–O4 locked 2026-11-26 (owner: O1A O2A O3A O4A). Remaining edges are implementation risks or Deferred.

### What we need to define (before start-task)
- Owner confirmation of `<implementation_plan>` (this file). Then explicit `start-task` (not auto).

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
| **L-O1A** | Minimal Hotwire **login + signup** HTML with allowlisted `return_to` under `/s/...` for Secret Link funnel. | owner 2026-11-26 O1A |
| **L-O2A** | Default `privacy_mode` on create = **`friends`** (no token until switched to `shared`). | owner 2026-11-26 O2A |
| **L-O3A** | Friend discovery via **`GET /api/v1/users/:username/wishlists`** (policy-scoped); keep public profile card thin. | owner 2026-11-26 O3A |
| **L-O4A** | Owner can **rotate** `share_token` while staying `shared` (invalidates old URL; revokes `secret_link` shares; keeps `explicit`). | owner 2026-11-26 O4A |
| **L-api-surface** | S3 API: owner CRUD wishlists; shares CRUD; rotate; `GET /shared_wishlists`; `GET /users/:username/wishlists`; soft-delete (+ restore for owner). | explore lock |
| **L-web-surface** | Web: `GET /s/:share_token` + OG + guest invitation CTAs; web auth pages for return_to only — no web wishlist CRUD. | D4a/D6a/O1A |
| **L-flutter-surface** | Flutter: my lists, create/edit, Shared with me, friend lists, empty detail shell, copy/rotate link; DesignTokens defaults. | D6a/D2b |
| **L-unfriend-shares** | On `Friendship#remove!`, delete `WishlistShare`s between the pair (share cleanup parity with block; avoids orphan explicit access). | Final check |

## Open (resolved — archive)

### O1 — Web auth HTML for Secret Link `return_to` (REQ-WISH-005)
**Context:** `/s/:share_token` is web Hotwire. Unauthenticated humans and crawlers hit it. After viewing the safe invitation, a guest must log in or sign up and land back on the same Secret Link. Today web `SessionsController` only `create`/`destroy` with no HTML forms and always redirects to health `root`. API signup exists; web signup does not.

**Option A — Minimal Hotwire login + signup with `return_to` (recommended):** Add thin HTML `new` (and create redirects) for web session + web signup (or reuse signup domain rules), validate `return_to` is a same-origin path under `/s/...`, restore after auth, then register Shared-with-me. Cost: small web surface in S3. Unlocks: full REQ-WISH-005 compliance and WhatsApp → browser → account → list flow.

**Option B — Web login only; signup Flutter-only:** Guests without accounts cannot complete the link on web. Cost: lower web work. Breaks SPEC wording ("login/sign-up") for the primary Secret Link surface.

**Option C — Defer return_to / treat as risk:** Ship OG + page without round-trip restore. Cost: lowest now. Leaves REQ-WISH-005 incomplete and a broken guest funnel.

**LOCKED → O1A** (owner 2026-11-26).

### O2 — Default `privacy_mode` on create
**Context:** Owner creates a wishlist before choosing audience.

**Option A — Default `friends` (recommended):** Safer; no `share_token` until owner switches to `shared` (or explicitly enables Secret Link). Matches anti-stalking posture.

**Option B — Default `shared`:** Generate `share_token` immediately; easier "copy link" UX but wider accidental exposure if owner forgets.

**LOCKED → O2A** (owner 2026-11-26).

### O3 — Friend discovery of accessible wishlists
**Context:** Accepted friends must be able to open `friends`-mode lists (and lists they are explicitly shared into). Profile search today never embeds wishlists (anti-stalking for strangers). Friends need a discovery path in Flutter.

**Option A — Nested index (recommended):** `GET /api/v1/users/:username/wishlists` policy-scoped to wishlists the viewer may see (empty for strangers → 404/empty per anti-stalking rules aligned with profile). Keeps `GET /users/:username` card thin.

**Option B — Embed wishlists on friend profile payload:** Only when `friendship_status=accepted`. Cost: couples profile to wishlist serialization; harder to paginate later.

**Option C — No friend index in S3; only "mine" + "Shared with me":** Friends cannot browse a friend's `friends`-mode lists until a later sprint — **violates** SPEC matrix row 2 for Sprint 3 privacy goals.

**LOCKED → O3A** (owner 2026-11-26).

### O4 — Rotate Secret Link while staying in `shared`
**Context:** SPEC mandates wipe on `shared`→`friends`. WhatsApp leak / accidental forward may need a new token without flipping mode.

**Option A — Explicit regenerate (recommended):** Owner action regenerates `share_token`, invalidates old URL, revokes `source: secret_link` shares (explicit friend shares stay). AuditEvent.

**Option B — Mode flip only:** Must switch to `friends` then back to `shared` to mint a new token. Cost: simpler API; worse UX; easy to forget re-adding selected friends.

**LOCKED → O4A** (owner 2026-11-26).

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

## Proposed S3 API surface (locked)
- `GET/POST /api/v1/wishlists` — mine (index/create; default `friends`)
- `GET/PATCH/DELETE /api/v1/wishlists/:id` — show/update/soft-delete
- `POST /api/v1/wishlists/:id/restore` — owner restore within SoftDeletable grace
- `POST /api/v1/wishlists/:id/shares` / `DELETE /api/v1/wishlists/:id/shares/:user_id` — explicit friend shares when `shared`
- `POST /api/v1/wishlists/:id/share_token/rotate` — O4A
- `GET /api/v1/shared_wishlists` — Shared with me
- `GET /api/v1/users/:username/wishlists` — O3A policy-scoped
- Web: `GET /s/:share_token` (Hotwire + OG); `GET/POST` web session + web signup with `return_to` (O1A)

## Proposed Flutter surfaces (locked)
- My wishlists list + create/edit privacy/event_date + copy/rotate Secret Link when shared
- Shared with me list
- Friend wishlists list (O3A) + wishlist detail empty shell
- DesignTokens defaults (D2b); bilingual AppStrings

## Dark corners & pitfalls (Final check 2026-11-26)
1. **Open redirect via `return_to`:** allowlist same-origin paths matching `\A/s/[A-Za-z0-9\-_]+\z` only; reject `//`, absolute URLs, other paths.
2. **Invalid / blocked / soft-deleted Secret Link:** respond **404** (no existence leak); OG must not render private titles for discarded lists.
3. **Owner opens own Secret Link:** idempotent — do not create a self `WishlistShare`; show owner shell.
4. **Unauthenticated human vs crawler:** both get invitation-level data only; after auth, empty wishlist shell (no items in S3).
5. **Unfriend vs Block:** Block already destroys shares; also destroy shares on friendship remove (**L-unfriend-shares**) so explicit shares cannot outlive friendship.
6. **Rotate vs mode flip:** rotate revokes only `secret_link` shares; explicit remain; mode→`friends` wipes token + secret_link shares.
7. **`activity_id` without FK:** nullable bigint, no FK until Activities exist — document in migration.
8. **Title limits:** implement as 1..100 grapheme-safe string (impl detail); no owner fork.
9. **Empty Flutter UX:** expected; copy "Sin ítems aún" — not a defect in S3 QA.
10. **Docs drift:** API_CONTRACT must gain wishlist section in-plan step 17; sync-docs pause remains a finish-branch concern later.

No remaining Open owner forks. Pitfalls recorded as risks / Locked mitigations above.

## Lock checklist (step 1.4)
- [x] Opening triad recorded
- [x] Classification: Feature
- [x] Domain Model populated (Wishlist, WishlistShare)
- [x] Final check / dark corners recorded
- [x] Every open question answered (O1A–O4A), deferred, or risk
- [x] `<implementation_plan>` written (TDD; ends at local green tests)
- [x] Behaviour matrix: owner **BM yes** — created `docs/core/BEHAVIOUR_MATRIX.md` (wishlist access actors BM-WISH-001..015)

## Plan confirmation (step 2.1) — 2026-11-26
- Owner: **CONTINUE / ACCEPT PLAN**
- Validation: Feature + `verification: tdd` → plan is test-first (failing specs before implement); aligns with SYSTEM_ARCHITECTURE (Rails Hotwire + `/api/v1` + Flutter; Pundit; no SPA). Plan ends at local green tests (no out-of-scope wrap-up steps).
- **Spec Locked.** Explore handoff ready. Do **not** auto-run start-task — owner must say `start-task` explicitly.

## Repo facts (main @ 8dd403c + explore branch)
- Product wishlist code still absent until start-task.
- `API_CONTRACT.md` wishlist section = plan step 17.
- `docs/core/BEHAVIOUR_MATRIX.md` seeded for Sprint 3 access actors.
  </working_notes>
</task_session>
