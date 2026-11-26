<task_session>
  <metadata>
    <task_name>MVP Sprint 5 — Secret Reservations (72h Grace Auto-Release & Context-Aware Limits)</task_name>
    <type>Feature</type>
    <req_id>REQ-RES-001, REQ-RES-002, REQ-RES-003, REQ-RES-004, REQ-RES-005, REQ-RES-006, REQ-LIFE-001 (reservation cancel on soft-delete), REQ-BLOCK-002 (cancel reservations on block), REQ-WISH-004 (estimated_date vs event_date warn), REQ-USER-003 (time_zone), REQ-NOTIF-001 (foundation per D5a), REQ-NOTIF-002 (device_tokens already exist), REQ-ARCH-003 (409 on unique race)</req_id>
    <roadmap_item>MVP Sprint 5 — Secret Reservations (72h Grace Auto-Release & Context-Aware Limits)</roadmap_item>
  </metadata>

  <working_notes>
## Base
- Repo: jotadugarte/wish-list-community
- origin/main @ 3f132f1 (Merge #11 Sprint 4 Items + Media)
- Prior locks: D5a notifications foundation before/with Sprint 5; D6a API+Flutter primary; D3a items already Done in S4
- Explore skill: no product code; no implementation branch/PR from this skill; no start-task until explicit owner order
- Parked stale pointers: Sprint 3 wishlists session (done) and broken Sprint 4 pointer (file missing after merge)

## Opening triad (2026-11-26)

### What we know
- Sprint 4 Items + Media is on main (#11). Items have CRUD, SoftDeletable, noop soft-delete hook placeholder for canceling reservations, `as_api_json` with **no** reservation fields yet.
- Wishlists already expose `max_reservations_per_user` (nil = unlimited) — schema ready for REQ-RES-005 personal lists.
- Block Wins + Friendship remove destroy shares; **no** Reservation cleanup hook yet (REQ-BLOCK-002 still pending for reservations).
- `DeviceToken` + unbind-on-logout already exist (REQ-NOTIF-002). No `Notification` / `NotificationPreference` / dispatcher / email templates yet.
- Solid Queue + `config/recurring.yml` exist (only finished-job cleanup in production).
- SPEC 4.5 + REQ-RES-001..006 are authoritative. Gift dual-path (`purchased_secret` → …) is **Sprint 6** on ROADMAP.
- Guests may view Secret Link items (S4 O1A) but must be logged in to reserve (REQ-WISH-002 / ROADMAP S5).
- Zero spoilers: owner never sees reservation state; mutations must not touch `items.updated_at` (REQ-RES-002).

### What we don't know (owner forks — cards below)
- O1: ~~LOCKED O1A~~ Bundle minimal notification foundation inside Sprint 5.
- O2: ~~LOCKED O2A~~ S5 extend + voluntary cancel only; mark purchased waits for Sprint 6.
- O3: ~~LOCKED O3A~~ Non-owners get viewer-relative availability; owner payloads omit it.
- O4: ~~LOCKED O4B~~ Hotwire Secret Link must offer the same reservation actions as the Flutter app (not API/Flutter-only).
- O5: ~~LOCKED O5A~~ Free estimated_date ≥ today (reserver TZ); grace → active.
- O6: ~~LOCKED O6A~~ Reserver may voluntarily cancel active/expired_grace → canceled.
- O7: ~~LOCKED O7A~~ Solid Queue recurring sweep (~10–15 min), idempotent.
- O8: ~~LOCKED O8A~~ Preferences table + API; defaults all-on; Flutter settings optional/light.

### What we need to define (before start-task)
- ~~Owner locks O1–O8~~ **Done** (O1A O2A O3A O4B O5A O6A O7A O8A).
- Final check + plan written; owner ordered **start-task** hands-off.

## Classification
**Feature** (new Reservation domain + API + Flutter + notification foundation + Solid Queue grace jobs).

## Process preference (owner 2026-11-26 — durable for explore-task)
- Ask decision cards **ONE at a time** with recommendation.
- Never batch multiple `O*` for a single reply.
- Await each answer before presenting the next card.
- Coordinator should persist this in Project preferences; session honors it from now.
- **Worker rule (owner 2026-11-26):** Do **not** ask remaining cards yourself — coordinator presents each card one-by-one; worker only records locks when relayed.
- **Card explanation rule (owner 2026-11-26):** Before listing options, explain the card in **plain concrete terms**: who sees what, what ships / what does not ship, and what changes for a real user. Avoid jargon-first framing. Then options + recommendation.

## Card queue status
- Locked: **O1A**, **O2A**, **O3A**, **O4B**, **O5A**, **O6A**, **O7A**, **O8A** (owner 2026-11-26) — **all cards done**
- Next card: (none)


## Prior locked anchors (carry forward)
| ID | Decision | Source |
| :--- | :--- | :--- |
| **L-D5a** | Notifications foundation **before/with Sprint 5** (not orphaned until S9). | pre-Sprint 3 review |
| **L-D6a** | Primary client = `/api/v1` + Flutter; web only where SPEC requires. | pre-Sprint 3 |
| **L-gift-s6** | Dual-path gift fulfillment + Received Gifts UI = Sprint 6 (S4 O7A deferred Received Gifts). | ROADMAP + S4 |
| **L-schema-max** | `wishlists.max_reservations_per_user` nil = unlimited (personal default). | SPEC / S3 schema |
| **L-device** | `device_tokens` bound to `api_token_id`; unbound on logout. | REQ-NOTIF-002 Done |
| **L-process** | TDD (`verification: tdd`); no start-task until explicit owner order. | config |
| **L-O1A** | Bundle minimal notification foundation **inside Sprint 5**: `notifications` (in-app), `notification_preferences`, single `NotificationDispatcher` (in-app + email enqueue; push no-op until S9 / Notifications MVP). Wire **only S5 events** now. | owner 2026-11-26 O1A |
| **L-O2A** | During 72h grace / active: reserver may **extend** or **voluntarily cancel** only; **mark purchased** (`purchased_secret`) waits for Sprint 6. REQ-RES-006 purchased escape completed jointly with S6. | owner 2026-11-26 O2A |
| **L-O3A** | Item API for non-owners includes viewer-relative `availability`: `available` \| `reserved_by_me` \| `unavailable`. Field **omitted** for owner (REQ-RES-002). Never expose reserver identity. S6 can map purchased → same `unavailable`. | owner 2026-11-26 O3A |
| **L-O4B** | Hotwire Secret Link must offer the **same reservation actions** as the Flutter app (not API/Flutter-only). Logged-in sharees on `/s/:share_token` can reserve / extend / cancel (and see availability) in parity with mobile. Narrows D6a for this sprint: Secret Link is an obligatory web reservation surface. | owner 2026-11-26 O4B |
| **L-O5A** | Extend: free `estimated_date` pick ≥ today in reserver `time_zone`; if status was `expired_grace`, transition back to `active` and clear grace deadline. | owner 2026-11-26 O5A |
| **L-O6A** | Reserver may voluntarily cancel `active` / `expired_grace` → `canceled` (frees partial unique slot; AuditEvent). | owner 2026-11-26 O6A |
| **L-O7A** | Grace/expiry via Solid Queue **recurring sweep** (~every 10–15 min): due `active` → `expired_grace` + notify; due grace → `auto_released` + notify. Idempotent batches; fits `recurring.yml`. | owner 2026-11-26 O7A |
| **L-O8A** | `notification_preferences` table + API; defaults **all-on** for S5 events; missing row = defaults-on. Flutter settings optional/light. Push preference stored; send may no-op until S9. | owner 2026-11-26 O8A |

## Domain Model (confirmed start-task 3.0 hands-off — Feature)

### Reservation
- **Responsibility:** Secret hold on one Item by one User (`active`, `expired_grace`, `auto_released`, `canceled`; `completed_by_gift` reserved for S6).
- **Invariants:**
  - At most one row per item with `status IN ('active','expired_grace')` — PostgreSQL partial unique index.
  - Reserver must have wishlist access (friend / explicit share / valid secret_link share) and not be owner; Block Wins denies.
  - Owner payloads never include reservation identity/state; reservation create/update/cancel/grace/auto-release **must not** change `items.updated_at`.
  - Soft-delete item/wishlist permanently cancels active/grace → no ghost on restore (REQ-LIFE-001).
  - Block (either direction) silently cancels active/grace between the pair (REQ-BLOCK-002).
  - Personal wishlist: count of reserver's active+grace on that wishlist must respect `max_reservations_per_user` when set (REQ-RES-005); Activities default-1 deferred to v1.
  - `estimated_date` interpreted in reserver `User#time_zone`; warn (non-blocking) if `> wishlist.event_date` when event_date present (REQ-WISH-004).
- **Value Objects / branded types:**
  - `ReservationStatus` — allowed statuses for S5 transitions
  - `EstimatedDate` — calendar date validated in reserver TZ (not raw String)
  - (reuse) access via existing WishlistPolicy / ItemPolicy

### Notification (foundation — O1)
- **Responsibility:** In-app record + dispatcher fan-out for S5 events (and stubs for email/push).
- **Invariants:** Single dispatcher entrypoint (REQ-NOTIF-001); respect per-event preferences when present; never notify wishlist owner of spoiler events (reservation created is **not** an owner event).

### NotificationPreference
- **Responsibility:** Per-user per-event channel toggles (`in_app`, `email`, `push`).
- **Invariants:** Defaults on for S5 reservation events unless owner picks otherwise (O8).

## Open decision cards (A = recommendation — ask ONE at a time)

> Owner process: present a single card, pause, lock, then next. Do not request `ACCEPT all A` in one shot.
> Before options: plain concrete brief (who sees what / what ships). Then options + recommendation.


### O1 — Notifications foundation depth (honors D5a)
**Context:** Sprint 5 events need user-visible alerts: grace entered, auto-released, reserved item critically edited or deleted (REQ-RES-003, REQ-RES-006). ROADMAP also has a separate “Notifications (MVP)” epic. DeviceToken exists; dispatcher/preferences/in-app store do not. D5a forbids leaving S5 orphaned.

**Option A — Bundle minimal foundation inside Sprint 5 (recommended):** Add `notifications` (in-app), `notification_preferences`, and a single `NotificationDispatcher` that always can create in-app rows, enqueues email jobs when preference allows (Action Mailer templates for S5 events), and **records/no-ops push** until FCM send lands in Sprint 9 / Notifications MVP. Wire only S5 events now. Cost: larger S5 PR. Unlocks: REQ-RES-003/006 without a blocking pre-chore; D5a satisfied “with” S5.

**Option B — Separate notifications chore PR before S5 impl:** Explore/start a thin foundation chore first, then S5 only consumes it. Cost: extra round-trip before reservations. Unlocks: cleaner PR boundaries; delays Secret Reservations.

**Option C — Defer user-facing notifs; AuditEvent only in S5:** Lowest code now. **Violates** REQ-RES-003/006 product behavior and D5a intent.

**LOCKED → O1A** (owner 2026-11-26).

### O2 — “Mark purchased” during 72h grace vs Sprint 6
**Context:** SPEC/ROADMAP say during grace the reserver can extend **or mark purchased**; else auto-release. “Mark purchased” is `purchased_secret` on the gift path (Sprint 6). Including full gifts blows S5 scope; omitting any escape hatch besides extend risks angry auto-releases.

**Option A — S5: extend + voluntary cancel only; purchased waits for S6 (recommended):** Grace actions = extend `estimated_date` (back to `active`) or cancel. Document that REQ-RES-006’s “mark purchased” escape is completed in Sprint 6. Cost: temporary SPEC wording gap until S6. Unlocks: clean S5/S6 split; still prevents stuck holds via cancel + auto-release.

**Option B — S5 adds `purchased_secret` terminal only (no deliver/confirm):** Thin gift stub. Cost: half a gift model early; serializers/status rules creep toward S6. Unlocks: literal SPEC escape hatch now.

**Option C — Pull dual-path gifts into S5:** Scope collapse with Sprint 6. Not recommended.

**LOCKED → O2A** (owner 2026-11-26).

### O3 — Friend-facing availability on items
**Context:** First-to-reserve is useless if other friends still see the item as free. ROADMAP Sprint 6 names the unified “Reserved / Unavailable” label for reserved **and** secretly purchased. S5 has no secret purchase yet, but still needs a non-spoiler signal for non-owners.

**Option A — Viewer-relative `availability` on item API for non-owners (recommended):** Values: `available` | `reserved_by_me` | `unavailable`. Omit field entirely for owner (REQ-RES-002). Never expose reserver identity. Cost: small serializer/policy branching. Unlocks: correct concurrency UX; S6 can map purchased → same `unavailable`.

**Option B — No friend signal until S6:** Only My Reservations knows. Breaks multi-friend lists.

**Option C — Early GiftRecord + full unified status machine in S5:** Over-scope.

**LOCKED → O3A** (owner 2026-11-26).

### O4 — Client surfaces (web vs Flutter)
**Context:** D6a = API+Flutter primary. Secret Link Hotwire already lists items read-only for logged-in sharees (S4 O1A). Reserve could stay mobile/API-only.

**Option A — API + Flutter only for reserve / My Reservations (recommended):** No Hotwire reserve controls in S5; web Secret Link stays view-only. Cost: web users must use the app to reserve. Unlocks: matches D6a; keeps web surface minimal.

**Option B — Minimal Hotwire reserve/cancel on `/s/:token` item rows:** Better web funnel. Cost: web auth + Turbo mutations + spoiler-safe UI; fights D6a unless SPEC demands it (it does not name web reserve).

**Option C — Full web My Reservations dashboard:** Parallel Flutter work; out of MVP posture.

**LOCKED → O4B** (owner 2026-11-26): Hotwire Secret Link must offer the **same reservation actions** as the Flutter app (not API/Flutter-only).

*(Original explore recommendation was O4A/API+Flutter-only; owner overrode to O4B with Hotwire parity.)*

### O5 — Extend semantics
**Context:** Reserver must be able to push `estimated_date` and exit grace.

**Option A — Free date pick ≥ today (reserver TZ); grace → active (recommended):** Clearing `grace_expires_at` when leaving `expired_grace`. Cost: date validation rules. Unlocks: flexible planning; matches private estimated_date model.

**Option B — Fixed +N days buttons only (e.g. +7/+14/+30):** Simpler UX, less flexible.

**Option C — Extend allowed only while `expired_grace`:** Blocks proactive reschedule while `active`.

**LOCKED → O5A** (owner 2026-11-26).

### O6 — Voluntary cancel
**Context:** Reserver may abandon a gift idea before auto-release.

**Option A — Allow cancel on `active`/`expired_grace` → `canceled` (recommended):** Frees partial unique slot; AuditEvent. Cost: one more mutation + Flutter action. Unlocks: good citizenship; pairs with O2A.

**Option B — No voluntary cancel:** Only auto-release, soft-delete, or block. Worse UX.

**LOCKED → O6A** (owner 2026-11-26).

### O7 — Grace / expiry scheduler
**Context:** Need reliable `estimated_date` → `expired_grace` and grace end → `auto_released` plus notifications, timezone-aware.

**Option A — Solid Queue recurring sweep (recommended):** e.g. every 10–15 minutes: (1) due active → expired_grace + notify; (2) due grace → auto_released + notify. Idempotent batch updates. Cost: up to ~15m lag. Unlocks: simple ops; fits existing `recurring.yml`.

**Option B — Schedule one Solid Queue job per reservation at create/extend:** Precise timing. Cost: job churn, cancel/reschedule complexity on every extend.

**Option C — External cron / clock process outside Solid Queue:** Diverges from architecture (Solid Queue is the queue).

**LOCKED → O7A** (owner 2026-11-26).

### O8 — Preferences & channels for S5
**Context:** REQ-NOTIF-001 wants per-event toggles. Flutter settings screen could wait.

**Option A — Preferences table + API; defaults all-on for S5 events; Flutter settings optional/light (recommended):** Dispatcher honors prefs; if no row, treat as defaults-on. Push send may no-op until S9 but preference flag is stored. Cost: small API. Unlocks: correct model without blocking on full settings UI.

**Option B — Hardcoded always-on in-app (+ email) until Notifications MVP:** Faster; weaker REQ-NOTIF-001.

**Option C — Full Flutter notification settings screen in S5:** More mobile scope.

**LOCKED → O8A** (owner 2026-11-26).

## Proposed API surface (locked draft)
- `POST /api/v1/items/:item_id/reservations` — create (409 on race / limit)
- `PATCH /api/v1/reservations/:id` — extend date / private note (reserver)
- `DELETE /api/v1/reservations/:id` — voluntary cancel (O6A)
- `GET /api/v1/my_reservations` — active + expired_grace for current user (REQ-RES-004)
- Item index/show: viewer-relative `availability` for non-owners (O3A); omitted for owner
- `GET/PATCH /api/v1/notification_preferences` — O8A
- `GET /api/v1/notifications` (+ mark read) — if O1A

## Proposed Flutter surfaces (draft)
- Reserve / extend / cancel from wishlist item detail (non-owner)
- Availability badge on item rows for non-owners
- **My Reservations** screen
- Light in-app notification inbox if O1A (optional minimal)
- Bilingual AppStrings; DesignTokens defaults (D2b)

## Proposed Hotwire surfaces (locked O4B)
- Secret Link `/s/:share_token` (logged-in sharee): **same reservation actions as Flutter** — reserve, extend, cancel, and availability display on item rows. Guests remain invitation/view rules per prior sprints (must log in to reserve).

## Out of scope (explicit)
- Gift dual-path / thank-you / Received Gifts (Sprint 6)
- FCM push send + Sprint 9 mobile wrap-up
- Activities reservation limits (v1; personal lists only in S5)
- Co-gifting / cooperacha
- Full standalone web My Reservations dashboard (O4C) — still out; Secret Link Hotwire parity is in via O4B

## Risks / impl notes (not owner forks yet)
- Touch `items.updated_at` on reserve → spoiler; use `update_columns` / separate table only.
- Owner editing critical fields must notify reserver without revealing to owner that a reservation exists (UI: owner just edits; server fans out).
- Partial unique + app-level limit checks; catch `RecordNotUnique` → 409 (REQ-ARCH-003).
- Unfriend: should cancel reservations between pair (parity with shares) — propose **L-unfriend-reservations** in Final check.
- Sweep job timezone: compare dates in reserver TZ, not UTC midnight blindly.
- Hotwire `/s/:token` item list **must** grow reserve/extend/cancel (+ availability) under O4B, in parity with Flutter; keep spoiler-safe (owner never sees reservation state on web either).

  

## Dark corners & pitfalls (Final check 2026-11-26)

1. **`items.updated_at` spoiler:** Reservation mutations must never touch `items.updated_at`.
2. **Owner payload leak:** Owner item JSON omits `availability` and reservation identity/state.
3. **Race on first reserve:** Partial unique index + `RecordNotUnique` → **409**.
4. **Limit TOCTOU:** Enforce `max_reservations_per_user` inside create transaction.
5. **Timezone sweep:** Use reserver `time_zone` for date/grace boundaries.
6. **Critical edit notify:** Notify reserver without revealing reservation to owner UI.
7. **Soft-delete ghosts:** Cancel active/grace on item soft-delete; no resurrect on restore.
8. **Block + unfriend:** Cancel active/grace between pair (`L-unfriend-reservations`).
9. **Guest Secret Link:** Must log in to reserve; then Hotwire parity (O4B).
10. **O4B parity:** Hotwire reserve/extend/cancel + availability; CSRF + Turbo.
11. **Push no-op:** Dispatcher may no-op FCM send in S5.
12. **No gift states in S5:** Do not transition to `purchased_secret` / gift path (O2A).
13. **event_date warn:** Soft warn if `estimated_date > event_date` (non-blocking).
14. **Docs:** Update API_CONTRACT + BM-RES-*; ROADMAP Done only after verify.

**Open owner forks:** none.
**L-unfriend-reservations:** On friendship remove, cancel active/grace between the pair.

## Lock checklist (step 1.4)

- [x] Opening triad recorded
- [x] Classification: Feature
- [x] Domain Model populated
- [x] Final check / dark corners recorded
- [x] O1A O2A O3A O4B O5A O6A O7A O8A locked
- [x] `<implementation_plan>` written (TDD; ends at local green tests)

## Plan confirmation — owner ordered start-task (2026-11-26)

- Owner: **start-task** hands-off. Explore handoff accepted. Spec locked.


  </working_notes>

  <implementation_plan>
    <step id="1" status="complete">Write failing RSpec model/VO specs for `Reservation` + `ReservationStatus` + `EstimatedDate`: S5 statuses (`active`, `expired_grace`, `auto_released`, `canceled`); private note; `estimated_date` in reserver TZ (≥ today on create/extend); partial unique index `WHERE status IN ('active','expired_grace')`; non-owner access required; owner cannot reserve own item. Trace `[REQ-RES-001]`, `[REQ-RES-002]`, `[REQ-USER-003]`, `[REQ-WISH-004]`.</step>
    <step id="2" status="complete">Implement migration + `Reservation` model/VOs minimally until step 1 green (no controllers). Do not mutate `items.updated_at` from reservation callbacks.</step>
    <step id="3" status="complete">Write failing `ReservationPolicy` specs: users with wishlist access (friend / explicit / secret_link), not blocked, not owner, may create; only reserver may extend/cancel. Trace `[REQ-RES-001]`, `[REQ-BLOCK-001]`, `[REQ-WISH-002]`.</step>
    <step id="4" status="complete">Implement `ReservationPolicy` (+ Scope for my_reservations) until step 3 green.</step>
    <step id="5" status="complete">Write failing request specs for create/extend/cancel: `POST /api/v1/items/:item_id/reservations`, `PATCH /api/v1/reservations/:id`, `DELETE /api/v1/reservations/:id`; `max_reservations_per_user`; concurrent second reserve → 409; O5A extend grace→active; O6A cancel. Trace `[REQ-RES-001]`, `[REQ-RES-005]`, `[REQ-ARCH-003]`.</step>
    <step id="6" status="complete">Implement reservation create/extend/cancel services + API controllers/routes/serializers until step 5 green.</step>
    <step id="7" status="pending">Write failing request specs for `GET /api/v1/my_reservations` (`active` + `expired_grace`). Trace `[REQ-RES-004]`.</step>
    <step id="8" status="pending">Implement My Reservations endpoint until step 7 green.</step>
    <step id="9" status="pending">Write failing specs for item `availability` (`available`|`reserved_by_me`|`unavailable`) for non-owners; omitted for owner; reservation paths do not change `items.updated_at`. Trace `[REQ-RES-002]`, O3A.</step>
    <step id="10" status="pending">Implement item serialization branching for `availability` until step 9 green.</step>
    <step id="11" status="pending">Write failing specs: soft-delete cancels active/grace; block cancels between pair; friendship remove cancels between pair. Trace `[REQ-LIFE-001]`, `[REQ-BLOCK-002]`.</step>
    <step id="12" status="pending">Implement SoftDeletable / UserBlock / Friendship cleanup hooks until step 11 green.</step>
    <step id="13" status="pending">Write failing specs for notification foundation: `Notification`, `NotificationPreference` (defaults all-on), `NotificationDispatcher` (in-app + email enqueue + push no-op); `GET/PATCH /notification_preferences`; `GET /notifications` (+ mark read). Trace `[REQ-NOTIF-001]`, O1A, O8A.</step>
    <step id="14" status="pending">Implement notification models, dispatcher, mailers/jobs stubs, preference/notification API until step 13 green.</step>
    <step id="15" status="pending">Write failing specs wiring S5 events: critical edit or soft-delete of reserved item notifies reserver; grace entered; auto-released. Trace `[REQ-RES-003]`, `[REQ-RES-006]`.</step>
    <step id="16" status="pending">Implement event hooks + services until step 15 green.</step>
    <step id="17" status="pending">Write failing specs for Solid Queue sweep job (O7A): due active→expired_grace + notify; due grace→auto_released + notify; idempotent; TZ-aware. Configure `recurring.yml`.</step>
    <step id="18" status="pending">Implement sweep job + recurring schedule until step 17 green.</step>
    <step id="19" status="pending">Write failing system/request specs for Hotwire Secret Link reservation parity (O4B): logged-in sharee reserve/extend/cancel + availability; guest cannot reserve; owner sees no spoilers. Trace `[REQ-WISH-002]`, `[REQ-RES-001]`, O4B.</step>
    <step id="20" status="pending">Implement Hotwire Turbo reservation actions/UI until step 19 green.</step>
    <step id="21" status="pending">Write failing Flutter tests: reserve/extend/cancel; availability badges; My Reservations; light prefs/inbox; AppStrings; DesignTokens. Trace REQ-RES-*.</step>
    <step id="22" status="pending">Implement Flutter repositories/screens/navigation until step 21 green.</step>
    <step id="23" status="pending">Update `API_CONTRACT.md`, expand `BEHAVIOUR_MATRIX.md` with BM-RES-*; touch DATA_FLOW_MAP only if needed. Do not mark ROADMAP Sprint 5 Done in this step.</step>
    <step id="24" status="pending">Run full backend RSpec + `flutter analyze` / `flutter test`; fix until green. End of start-task implementation scope.</step>
  </implementation_plan>

</task_session>
