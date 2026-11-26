<task_session>
  <metadata>
    <task_name>MVP Sprint 4 — Items + Media + Automatic Store Image Extraction</task_name>
    <type>Feature</type>
    <req_id>REQ-ITEM-001, REQ-ITEM-002, REQ-ITEM-003, REQ-ITEM-005, REQ-ITEM-006, REQ-ARCH-002 (items schema readiness), REQ-LIFE-001 (item soft-delete cascade + wishlist→items cascade), REQ-WISH-* (view items only when wishlist visible), REQ-BLOCK-001 (Block Wins on item access)</req_id>
    <roadmap_item>MVP Sprint 4 — Items + Media + Automatic Store Image Extraction</roadmap_item>
    <created_at>2026-11-26</created_at>
    <base_sha>1384f64</base_sha>
    <base_ref>origin/main</base_ref>
  </metadata>

  <working_notes>
## Base
- Repo: jotadugarte/wish-list-community
- origin/main @ `1384f64` (Merge #10 Sprint 3 docs sync) — agentic:guild 1.1.0
- start-task hands-off on `cursor/feat-sprint-4-items-media-ab93`
- Prior locks carried forward: **D3a** (items = S4), **D6a** (API+Flutter primary; web only where SPEC requires), **D2b** (DesignTokens defaults), TDD verification, no `start-task` until owner says so

## Opening triad (2026-11-26)

### What we know
- Sprint 3 merged: `Wishlist` / `WishlistShare`, Pundit matrix, API shells, Flutter empty detail, Hotwire `/s/:share_token` OG invitation + `return_to`, SoftDeletable + User→Wishlist cascade.
- **No** `items` / `item_links` tables, models, routes, ActiveStorage blob tables, or Flutter item UI yet. `image_processing` gem present; ActiveStorage engine loaded; storage = Disk (`local`/`test`); **no** `active_storage_*` migrations in schema.
- SPEC §4.4 + REQ-ITEM-001..003,005,006 + DESIGN_SYSTEM specs box + DATA_FLOW_MAP image/soft-delete rows + TESTING_STRATEGY (WebMock OG + SSRF private-IP cases) are authoritative.
- Soft-delete cascade wishlist→items and item restore-without-ghost-reservations is specified; **Reservation model does not exist yet** (S5) — S4 registers hooks with empty/no-op reservation cancel bodies ready for S5 fill-in.
- API_CONTRACT §3 still says "Empty wishlist shells (no items)" — S4 must extend contract.
- BEHAVIOUR_MATRIX exists (BM-WISH-001..015 automated); needs BM-ITEM-* rows in explore/plan (not declined).
- ROADMAP still lists Sprint 3 as unchecked (docs hygiene debt; not S4 product scope).
- qa_profile: headless Flutter + RSpec only; owner runs simulators.

### What we don't know (owner forks)
- None material — **O1A–O8A locked 2026-11-26** by owner. Remaining edges are implementation risks or Deferred.

### What we need to define (before start-task)
- O1–O8 locked; Domain Model confirmed; Final check recorded; plan written; owner authorized **start-task** hands-off.

## Classification
**Feature** (new domain entities + media pipeline + OG extractor + API + Flutter; minimal Hotwire only if O1A).

## Locked (from SPEC + architecture + prior sprints)

| ID | Decision | Source |
| :--- | :--- | :--- |
| **L-D3a** | Items + media + store OG extract = Sprint 4; no reserve/gift. | pre-Sprint 3 / ROADMAP |
| **L-D6a** | Primary client = `/api/v1` + Flutter. Web only where SPEC forces (Secret Link). Full web item CRUD **out**. | pre-Sprint 3 D6a |
| **L-D2b** | DesignTokens defaults; Ñata retoken later. Specs box uses `specBg` + accent border. | DESIGN_SYSTEM / D2b |
| **L-unit** | `1 Item = 1 giftable unit` (no quantity field in MVP). | REQ-ITEM-005 |
| **L-fields** | Item has `title`, prominent `specifications`, `priority` ∈ {low, medium, high, must_have}, nullable `price_cents`/`currency` (REQ-ARCH-002), multiple `ItemLink`s. | REQ-ITEM-001/003, ARCH-002 |
| **L-links** | `ItemLink` URLs via `ExternalUrl` VO: strict `http`/`https` only. | SPEC 4.4 / REQ-ITEM-001 |
| **L-media** | Max 3 images/item; ≤2MB each; ≤1600px longest side; server WebP + full EXIF/GPS strip via libvips; never persist EXIF. | REQ-ITEM-002 / Kill List |
| **L-og** | Best-effort `og:image` + `og:title` on paste/share of store link; **SSRF protection required** (reject private/link-local/metadata IPs). | REQ-ITEM-006 / TESTING_STRATEGY |
| **L-ssrf-tests** | OG/network tests use WebMock (or equivalent); never live Amazon/ML; SSRF cases include 127.0.0.1, 10/8, 169.254.169.254. | TESTING_STRATEGY |
| **L-life** | SoftDeletable on Item; wishlist soft-delete cascades soft-delete items; restore restores items; reservation cancel hook registered but no-op until S5 (zero ghosts when S5 arrives). | REQ-LIFE-001 / DATA_FLOW_MAP |
| **L-access** | Item visibility follows WishlistPolicy (owner / friends-mode friend / sharee). Mutations = owner only. Block Wins → 404. | REQ-WISH-001 / BLOCK-001 |
| **L-spoiler-ready** | Schema/serializers must not paint a corner that forces `touch` on reservation later; associations that will attach Reservation use `touch: false` from day one. | REQ-RES-002 / Kill List |
| **L-no-gift-logic** | No reservation/gift state machine, no thank-you, no My Reservations in S4. | ROADMAP S5/S6 |
| **L-no-share-sheet** | Native OS Share-to-App stays Sprint 9; S4 may offer in-app paste URL → extract. | REQ-MOB-001/002 |
| **L-ast-disk** | ActiveStorage Disk (`local`/`test`) for MVP; S3/object store is infra later (not blocking S4). | storage.yml + no ADR |
| **L-process** | TDD; explore → owner locks → plan → explicit `start-task`; this skill never implements. | config + explore-task |
| **L-bm** | Behaviour matrix exists; S4 will add BM-ITEM-* rows (planned→automated in impl). | BEHAVIOUR_MATRIX.md |
| **L-O1A** | Hotwire Secret Link shows **read-only item list** after auth; guests keep invitation-only OG. | owner 2026-11-26 O1A |
| **L-O2A** | OG extract **synchronous** in-request with hard timeout (3–5s); best-effort empty on failure. | owner 2026-11-26 O2A |
| **L-O3A** | OG returns **preview**; owner confirms before persist. | owner 2026-11-26 O3A |
| **L-O4A** | Images via **multipart** on item create/update + attach/detach. | owner 2026-11-26 O4A |
| **L-O5A** | `price_cents`/`currency` in schema+API **and** optional Flutter fields. | owner 2026-11-26 O5A |
| **L-O6A** | Client-side Flutter compression **deferred to S9**. | owner 2026-11-26 O6A |
| **L-O7A** | Received Gifts UI **deferred to S6**. | owner 2026-11-26 O7A |
| **L-O8A** | Per-wishlist integer **`position`**; owner reorder; default append. | owner 2026-11-26 O8A |
| **L-api-surface** | Nested items CRUD; restore; multipart; link_previews; reorder; separate index. | explore lock |
| **L-web-surface** | O1A read-only items on authorized `/s/:token`. | O1A |
| **L-flutter-surface** | Detail list + add/edit + preview confirm; specs; optional price. | O3A/O5A |

## Open (resolved — archive)

**LOCKED → O1A O2A O3A O4A O5A O6A O7A O8A** (owner 2026-11-26). Essay cards lived in explore session history (`ca43884`).

## Deferred (parked — out of Sprint 4 product scope)

| Item | Parking note |
| :--- | :--- |
| Reservations / grace / limits / My Reservations | Sprint 5 — register SoftDeletable cancel hooks as no-op |
| Gift fulfillment / thank-you / Received Gifts UI | Sprint 6 (O7A) |
| REQ-RES-003 reserver notifications on critical edits | Needs notification foundation (D5a) + Reservation |
| Native Share-to-App sheet | Sprint 9 REQ-MOB-001/002 |
| Client-side image compression | Sprint 9 (O6A) |
| Object storage (S3) for ActiveStorage | Infra / deploy; Disk OK for MVP |
| Full web item CRUD / admin media tools | Not S4 (D6a) |
| Ñata visual retoken | D2b when HTML arrives |
| Validate price against link | Backlog |
| Public Discover | Removed onda 2 |

## Implementation risks (not owner forks)

| Risk | Mitigation |
| :--- | :--- |
| No `active_storage_*` tables yet | First TDD steps include ActiveStorage install migrations |
| No WebMock gem yet | Add to `:test` and stub all OG HTTP; SSRF unit tests on `ExternalUrl` / fetcher |
| SSRF DNS rebinding | Resolve IP before connect; block private ranges; no redirects to private; timeout |
| Wishlist soft-delete without item cascade today | Register Wishlist soft_delete/restore hooks cascading Items in S4 |
| User account soft-delete already cascades Wishlists | Wishlist→Items cascade covers account path once wired |
| OG HTML parsers brittle per store | Best-effort; failure → empty preview; never raise 500 for "no og tags" |
| Image bomb / decompression | Enforce byte limit before process; libvips; max dimensions |
| Multipart size / Puma | Rack/request size limits aligned with 3×2MB + JSON |
| Secret Link OG vs item OG confusion | WhatsApp card stays invitation-only; store OG is **server-side extract into item**, never into share preview |
| ROADMAP Sprint 3 still `[ ]` | Hygiene via sync-docs/roadmap-manage — not S4 impl |
| Flutter detail is empty shell | Replace with item list + add/edit; keep privacy/rotate chrome |

## Domain Model confirmation (start-task 3.0)
Hands-off: confirmed VOs `ExternalUrl`, `ItemPriority`, `ImageDimensions` as explored — no renames.

## Domain Model (CbC — confirmed start-task hands-off 2026-11-26)

### Entity: `Item`
- **Responsibility:** One giftable unit inside a `Wishlist` with title, specifications, desire priority, optional price, purchase links, position, and up to 3 processed images.
- **Invariants:** Belongs to kept Wishlist; owner mutations; viewers via WishlistPolicy; SoftDeletable + wishlist cascade; max 3 images (2MB/1600/WebP/EXIF strip); `ItemPriority` default medium; price pair both-null or both-present; `position` ≥ 0; reservation assoc later with `touch: false`.
- **Value Objects:** `ItemPriority`, `ImageDimensions`.

### Entity: `ItemLink`
- **Responsibility:** Purchase URL rows for an Item.
- **Invariants:** `ExternalUrl` http/https; belongs to Item.
- **Value Objects:** `ExternalUrl` (SSRF gate for OG).

### Supporting
- Wishlist hooks, ItemPolicy, SoftDeletable, AuditEvent, ActiveStorage Disk, OpenGraphPreview sync service.

### Out of S4
- Reservation, GiftRecord, Activities, RES-003 notifications, Share Sheet, client compression.

## Proposed S4 API surface (locked)
- `GET/POST /api/v1/wishlists/:wishlist_id/items`
- `GET/PATCH/DELETE /api/v1/items/:id` (multipart images)
- `POST /api/v1/items/:id/restore`
- `DELETE /api/v1/items/:id/images/:image_id`
- `PATCH /api/v1/wishlists/:wishlist_id/items/reorder` `{ item_ids: [] }`
- `POST /api/v1/link_previews` `{ url }` → preview (O2A/O3A)
- Wishlist show stays shell; load items via nested index

## Proposed Flutter surfaces (locked)
- Detail item list + specs box; add/edit; paste-URL preview confirm; optional price; no reserve/gift/Share Sheet; no client compress

## Behaviour matrix (impl docs step)
BM-ITEM-001..010 planned→automated with tests.

## Dark corners & pitfalls (Final check 2026-11-26)
1. WhatsApp Secret Link OG stays invitation-only; store OG never feeds share meta.
2. SSRF: resolve IP before connect; block private/link-local/metadata; no redirect to private; timeout.
3. Install ActiveStorage migrations; Disk only.
4. Wishlist→Item cascade hooks; User→Wishlist inherits.
5. Multipart size limits before libvips; max 3 images.
6. On confirm, re-validate remote image URL SSRF server-side (or mint server preview token).
7. price_cents/currency pair invariant.
8. Reservation path must not touch item.updated_at (S5 readiness).
9. Reservation cancel hook registered no-op until S5.
10. Add WebMock for OG/SSRF specs.

## Lock checklist (2026-11-26)
- [x] Opening triad · Feature classification · Domain Model · Final check · O1A–O8A locked · BM exists · plan below

  </working_notes>

  <implementation_plan>
    <step id="1" status="complete">Write failing RSpec for Value Objects `ExternalUrl` (http/https only; reject javascript/data/file) and `ItemPriority` (low/medium/high/must_have). Trace `[REQ-ITEM-001]`, `[REQ-ITEM-003]`.</step>
    <step id="2" status="complete">Implement `ExternalUrl` and `ItemPriority` minimally until step 1 green.</step>
    <step id="3" status="complete">Write failing RSpec for `Item` + `ItemLink` models: belongs_to wishlist, SoftDeletable, priority default medium, price pair invariant, position default append, links, `has_many_attached :images` (max 3). Trace `[REQ-ITEM-001]`, `[REQ-ITEM-002]`, `[REQ-ITEM-003]`, `[REQ-ITEM-005]`, `[REQ-ARCH-002]`, `[REQ-LIFE-001]`.</step>
    <step id="4" status="complete">Implement ActiveStorage install migrations + `items`/`item_links` migrations + models until step 3 green. Add WebMock to test Gemfile group. No controllers yet.</step>
    <step id="5" status="complete">Write failing specs for Wishlist soft_delete/restore cascading Items (documented no-op reservation cancel hook). Trace `[REQ-LIFE-001]`.</step>
    <step id="6" status="complete">Implement Wishlist→Item SoftDeletable hooks until step 5 green.</step>
    <step id="7" status="complete">Write failing `ItemPolicy` specs: owner CRUD; wishlist viewers can read; strangers/blocked deny; restore owner-only. Trace `[REQ-WISH-001]`, `[REQ-BLOCK-001]`, `[REQ-ITEM-001]`.</step>
    <step id="8" status="complete">Implement `ItemPolicy` until step 7 green.</step>
    <step id="9" status="complete">Write failing specs for image processing: reject oversize/>3; resize ≤1600; WebP; EXIF/GPS stripped. Trace `[REQ-ITEM-002]`.</step>
    <step id="10" status="complete">Implement image processing (ActiveStorage + libvips) until step 9 green.</step>
    <step id="11" status="complete">Write failing specs for sync OpenGraph preview + `POST /api/v1/link_previews` (mocked success; SSRF rejects; timeout empty; auth). Trace `[REQ-ITEM-006]`.</step>
    <step id="12" status="complete">Implement OpenGraph preview service + link_previews endpoint until step 11 green (O2A/O3A).</step>
    <step id="13" status="complete">Write failing request specs for items API CRUD/restore/multipart/reorder/links/price/Pundit 404. Trace `[REQ-ITEM-001..003]`, `[REQ-ITEM-005]`, `[REQ-ARCH-002]`, `[REQ-LIFE-001]`.</step>
    <step id="14" status="complete">Implement API controllers/routes/serializers until step 13 green (O4A/O8A; O3A confirmed preview apply).</step>
    <step id="15" status="complete">Write failing specs for Hotwire `/s/:share_token`: guest OG invitation-only; authorized viewer read-only items. Trace `[REQ-WISH-005]`, `[REQ-ITEM-001]`, O1A.</step>
    <step id="16" status="complete">Implement Hotwire Secret Link read-only items until step 15 green.</step>
    <step id="17" status="complete">Write failing Flutter tests for item list/add/edit/preview/price/specs/bilingual. Trace REQ-ITEM-*.</step>
    <step id="18" status="complete">Implement Flutter screens/repos until step 17 green.</step>
    <step id="19" status="complete">Update API_CONTRACT, BEHAVIOUR_MATRIX BM-ITEM-*, ROADMAP Sprint 4 verified slices only.</step>
    <step id="20" status="complete">Run full RSpec + flutter analyze/test until green. End of start-task scope.</step>
  </implementation_plan>
</task_session>
