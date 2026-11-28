# Explore Session — v1 Sprint B Activities (Lists + Reservations + Budget Enforcement)

**Classification:** Feature  
**Discovery:** COMPLETE — plan CONFIRMED (owner 2026-11-28, America/Costa_Rica). Ready for `start-task` handoff.  
**Skill:** explore-task  
**Owner language:** español cotidiano (“en cristiano”); teléfono vs web primero; una carta O* a la vez  
**Base:** `origin/main` @ `18d8a49` (Merge PR #20 — Sprint A ROADMAP Done; product Sprint A = PR #19)  
**Explore doc:** `/cursor/stores/bc-32a5179f-cc50-4940-94d7-70abc32641c4/docs/explore-v1-sprint-b-activities.md`  
**Parallel:** Ñata visual (WLC-28) waiting — do not block; DesignTokens defaults OK  
**Constraint:** Do not re-litigate Sprint A locks unless owner asks absorb

## Opening triad

### What we know
- ROADMAP backlog #1 on `origin/main`: **v1 Sprint B — Activities (Lists + Reservations + Budget Enforcement)** with three bullets:
  1. Each user adds their activity items (manual price + currency) — `REQ-ACT-005`
  2. Reservations within an activity (default 1 active reservation per participant in `secret_santa`; configurable in `open_gifting`) — `REQ-RES-005`
  3. Budget validation enforcing the activity's chosen `budget_mode` (`fixed`, `min_only`, `max_only`, `range`) — `REQ-ACT-005`
- **O1B LOCKED** (owner 2026-11-28, America/Costa_Rica): those three ROADMAP bullets **plus** full purchased/received gift Path 1/2 **plus** 72h grace inside the activity. Out still: Cooperacha, email confirmation, “don’t repeat last year”, price-from-link validation, re-litigate A, Ñata.
- **O2A LOCKED** (owner 2026-11-28, America/Costa_Rica): reuse `Wishlist` + `activity_id`, one per participant; personal lists stay separate.
- **O3A LOCKED** (owner 2026-11-28, America/Costa_Rica): honor `visibility_mode` + `reservation_visibility`; no self-reserve; reserves only after seal (draw/Arrancar); fill lists before seal OK.
- **O4A LOCKED** (owner 2026-11-28, America/Costa_Rica): block on add if price breaks `budget_mode`; re-check on reserve; `none` = no amount check. Same currency as activity.
- **O5A LOCKED** (owner 2026-11-28, America/Costa_Rica): `secret_santa` = 1 active reservation per participant; `open_gifting` = creator/co-org sets N (default 1) before seal via activity wishlist `max_reservations_per_user` (or equivalent).
- **O6A LOCKED** (owner 2026-11-28, America/Costa_Rica): full B notification catalog (item-touched-with-reserve, reserve/release/grace, purchased/delivered/received, budget-rejected to item owner) via inbox/email/push + prefs (`REQ-NOTIF-001`).
- Sprint A is **Done** on main (PR #19 product + PR #20 ROADMAP). Shell shipped: Activity + participants + exclusions + draw/Blind Bridge + open_gifting seal + API/Hotwire/Flutter + activity notification catalog. Ops risks deferred (owner-device QA, live SMTP/FCM) — do not block B.
- Sprint A locks absorbed as background (not reopened): O1A–O8A, FC1A–FC3A, ACCEPT parks — especially: `visibility_mode` / `reservation_visibility` **stored in A, applied in B**; `budget_mode` configured in A, **enforcement in B**; activity items/lists were explicitly out of A (O4B).
- Schema readiness: `wishlists.activity_id` nullable + `max_reservations_per_user`; `items.price_cents` / `currency`; personal Reservation + gift + grace stack already exists (B will wire it into activity context per O1B); `BudgetMode` VO validates config bounds (not item/reservation enforcement yet).
- Preferences: web+Flutter parity; REQ-ID hard gate; one O* card at a time; Spanish en cristiano; Ñata does not block.

### What we don't know (material — resolve via O* cards one at a time)
- ~~none material~~ — discovery closed.

### What we need to define
- Launch **`start-task`** (hands-off per prefs) on a **new worker** using this session’s `<implementation_plan>`.

## Sprint A locks (absorb only — do not re-litigate)

| Lock | Meaning for B |
| :--- | :--- |
| O1A | A was shell only; B owns lists/reservations/budget enforcement |
| O2B | Money/visibility freeze layers already exist; B must respect freezes |
| O3B | Creator + co-orgs same admin powers |
| O4B | A had board + bridge to personal lists; **activity-scoped lists land in B** |
| O5B | Opaque `/a/:token` + deep link parity already shipped |
| O6A | open_gifting has no draw; seal via Arrancar |
| O7B / FC1A | Dropout / block recovery already defined |
| O8A | A notification catalog shipped; **item/reservation activity events are B** |
| ACCEPT parks | Apply `visibility_mode` + `reservation_visibility` in B; DesignTokens later |

## Scope table (**O1B LOCKED**)

| In Sprint B | Out |
| :--- | :--- |
| Activity items with manual price + currency (`REQ-ACT-005`) | Cooperacha / co-gifting |
| Activity reservations + SS default 1 / open_gifting configurable (`REQ-RES-005`) | Email confirmation |
| Enforce `budget_mode` on items/reservations (`REQ-ACT-005`) | “Don’t repeat last year’s gift” |
| Apply parked A visibility/reservation modes | Validate price against store link |
| Full gift Path 1/2 (purchased → delivered → received) inside activity | Re-open Sprint A draw/bridge/invite design |
| 72h grace / auto-release inside activity (`REQ-RES-006` context) | Ñata visual / DesignTokens retokenize |
| Web + Flutter parity for all of the above | |

## Decision cards

### O1 — ¿Qué entra en este sprint? — **LOCKED B** (owner 2026-11-28, America/Costa_Rica)

ROADMAP three bullets + full purchased/received gift flow + 72h grace inside activity. Cooperacha / email / don’t-repeat / price-link / A re-litigation / Ñata stay out.

### O2 — ¿Dónde vive la lista de regalos de la actividad? — **LOCKED A** (owner 2026-11-28, America/Costa_Rica)

Reuse `Wishlist` + `activity_id`: one activity-scoped wishlist per participant. Personal wishlists stay separate. Item / Reservation / GiftRecord / 72h grace reuse in that context (`REQ-ARCH-002`).

### O3 — ¿Quién ve las listas y quién puede reservar? — **LOCKED A** (owner 2026-11-28, America/Costa_Rica)

Honor A’s `visibility_mode` + `reservation_visibility`. Secret Santa / open_gifting as labeled. No self-reserve. Reserves only after seal; participants may add items before seal.

### O4 — ¿Cuándo y cómo se hace cumplir el presupuesto? — **LOCKED A** (owner 2026-11-28, America/Costa_Rica)

Block on add if price breaks mode; re-check on reserve; `none` = no amount check. Activity currency; missing price when mode requires amount → block.

### O5 — ¿Cuántas reservas activas por persona en regalos abiertos? — **LOCKED A** (owner 2026-11-28, America/Costa_Rica)

`secret_santa` fixed at 1 active reservation per participant. `open_gifting`: creator/co-org picks N (default 1) before seal. Parity web + app (`REQ-RES-005`).

### O6 — ¿Qué avisos nuevos de la actividad entran en B? — **LOCKED A** (owner 2026-11-28, America/Costa_Rica)

Full B catalog: item touched while reserved, reserve/release/grace, purchased/delivered/received, budget rejected (to item owner). Inbox + email + push + prefs. Activity-scoped copy where needed.

## Dark corners & pitfalls

Documented at Final check (Phase 1.3). FC cards one at a time.

1. **Surfacing:** activity wishlists only inside activity surfaces — **FC1A LOCKED**
2. **Dropout / leave / cancel / Block Wins:** auto-clean — **FC2A LOCKED**
3. **open_gifting N after seal:** freeze at Arrancar — **FC3A LOCKED**
4. **Activity wishlist privacy_mode / share_token:** no Secret Link — **FC4A LOCKED**
5. **Currency:** items must use activity currency — **ACCEPT park** (hard enforce in plan)
6. **visible_to_recipient vs personal zero-spoiler:** activity-only override — **ACCEPT park** (follows O3A)

### FC1 — ¿Las listas de la actividad aparecen en “Mis listas”? — **LOCKED A** (owner 2026-11-28, America/Costa_Rica)

Activity wishlists only inside activity surfaces (board / activity detail / activity flows). Not mixed into personal “My Wishlists”.

### FC2 — Si alguien se sale, lo sacan, cancelan o hay bloqueo — **LOCKED A** (owner 2026-11-28, America/Costa_Rica)

Auto-clean: cancel touched open reserves/gifts; archive leaver’s activity list; notify affected; keep Sprint A bridge/redraw / cancel-all behavior. Block Wins uses the same cleanup family.

### FC3 — ¿Se puede cambiar el N de reservas en regalos abiertos después del sello? — **LOCKED A** (owner 2026-11-28, America/Costa_Rica)

Freeze open_gifting N at Arrancar/seal; no raise or lower after seal. Pre-seal edits still allowed (with O2B freezes respected).

### FC4 — ¿Las listas de la actividad pueden tener enlace secreto / privacidad de lista personal? — **LOCKED A** (owner 2026-11-28, America/Costa_Rica)

No Secret Link / no personal friends/shared privacy on activity wishlists. Access only via accepted participation + O3A visibility/reservation rules.

### ACCEPT parks — **LOCKED** (owner 2026-11-28, America/Costa_Rica)

- Activity item currency must equal activity currency (hard server enforce).
- `visible_to_recipient` intentionally overrides personal zero-spoiler inside activity only; `hidden_from_recipient` keeps recipient blind to hold as labeled.

## Domain Model

**Feature — FINALIZED for plan**

| Entity / VO | Responsibility | Invariants |
| :--- | :--- | :--- |
| `Wishlist` (activity-scoped) | One per accepted participant; `activity_id` set; not in personal My Wishlists | No share_token; no personal privacy modes; archived on leave/cancel/Block (FC2A); ensure-on-accept |
| `Item` | Giftable unit on activity wishlist; manual price_cents + currency | Currency == activity currency; BudgetEnforcement on create/update (O4A); soft-delete cancels holds |
| `Reservation` | Activity-context hold | No self-reserve; only after seal; SS max 1 / open N; O3A reservation_visibility |
| `GiftRecord` | Path 1/2 + thank-you in activity | Personal semantics; activity-scoped notifications |
| `BudgetEnforcement` | Applies BudgetMode to price and reserve | none skips; missing price when required blocks; re-check on reserve |
| `ReservationLimit` | max_reservations_per_user on activity wishlist | SS=1; open N pre-seal; freeze at Arrancar (FC3A) |
| `ActivityVisibilityGate` | Who views/reserves whose list | visibility_mode + assignment_mode; Block Wins |
| `ActivityBNotifier` | B catalog events | Prefs + dispatcher; activity copy |

**Value Objects:** ActivityCurrency, BudgetMode, ReservationVisibility, VisibilityMode, EstimatedDate, ReservationStatus, GiftStatus.

## REQ trace (Sprint B candidates)

| REQ-ID | Role in B |
| :--- | :--- |
| `REQ-ACT-005` | Manual price+currency on activity items + enforce budget_mode |
| `REQ-RES-005` | Context-aware reservation limits inside activities |
| `REQ-ARCH-002` | `activity_id` / price readiness already on schema |
| `REQ-RES-001`..`004`, `006` | **In scope via O1B** — reuse personal reservation/gift/grace invariants inside activity |
| `REQ-GIFT-001`..`004` | **In scope via O1B** — Path 1/2 + thank-you semantics inside activity |
| `REQ-BLOCK-001` | Block Wins still wins inside activities |
| `REQ-ACT-001` | Visibility/reservation modes apply on B surfaces |

## Lock checklist (1.4)

- [x] Opening triad recorded
- [x] Classification = Feature
- [x] Domain Model populated (Feature)
- [x] Final check done; dark corners recorded
- [x] Every open question answered, deferred, or ACCEPT park
- [x] Behaviour matrix already exists — offer skipped
- [x] TDD implementation plan inserted below (no finish-branch / PR / QA / merge steps)

## Status

- **DISCOVERY COMPLETE** — owner **CONFIRM PLAN** 2026-11-28 (America/Costa_Rica). Spec + Domain Model + TDD plan **LOCKED**.
- Phase 2 / Step 2.1 done. Handoff: owner/coordinator runs **`start-task`** on a **new worker**. This explore writes no application code.

<implementation_plan>
  <step status="complete" id="1">Write failing specs for ensuring one activity-scoped Wishlist per accepted participant (activity_id, owner=participant, excluded from personal My Wishlists index, no share_token / no personal privacy switch). Trace [REQ-ARCH-002], [REQ-ACT-001], FC1A, FC4A.</step>
  <step status="complete" id="2">Implement ensure-on-accept (and backfill helper for already-accepted) until step 1 green — models/services only.</step>
  <step status="complete" id="3">Write failing specs for activity item create/update: manual price+currency rules; currency must equal activity currency; BudgetEnforcement blocks when mode is fixed/min_only/max_only/range and price invalid or missing; none allows missing/any price. Trace [REQ-ACT-005], O4A.</step>
  <step status="complete" id="4">Implement item budget/currency guards until step 3 green.</step>
  <step status="complete" id="5">Write failing specs for ActivityVisibilityGate: secret_santa vs open_gifting + visibility_mode; never reserve own list; pre-seal add-items OK; reserves forbidden until seal. Trace [REQ-ACT-001], O3A.</step>
  <step status="complete" id="6">Implement visibility/seal gates until step 5 green.</step>
  <step status="complete" id="7">Write failing specs for activity reservations: reuse Reservation concurrency [REQ-RES-001]; reservation_visibility owner payload rules; SS max_reservations_per_user=1; open_gifting uses configured N; N editable only pre-seal and freezes at Arrancar; re-check budget on reserve. Trace [REQ-RES-005], [REQ-ACT-005], O4A, O5A, FC3A.</step>
  <step status="complete" id="8">Implement reservation limit + freeze-N + budget re-check until step 7 green.</step>
  <step status="complete" id="9">Write failing specs for gift Path 1/2 + thank-you + 72h grace/auto-release on activity items (reuse services; activity-context notifications). Trace [REQ-GIFT-001]..[004], [REQ-RES-006], O1B.</step>
  <step status="complete" id="10">Implement/wire gift+grace in activity context until step 9 green.</step>
  <step status="complete" id="11">Write failing specs for FC2A cleanup hooks: leave / cancel activity / Block Wins cancel touched open reserves+gifts, archive leaver activity wishlist, notify; compose with existing A bridge/redraw. Trace [REQ-BLOCK-001], [REQ-ACT-003], [REQ-LIFE-001], FC2A.</step>
  <step status="pending" id="12">Implement cleanup hooks until step 11 green.</step>
  <step status="pending" id="13">Write failing specs for O6A notification catalog + preference keys (activity-scoped copy): item touched while reserved, reserve/release/grace, purchased/delivered/received, budget rejected to item owner. Trace [REQ-NOTIF-001], O6A.</step>
  <step status="pending" id="14">Implement Activity B notifier + prefs until step 13 green.</step>
  <step status="pending" id="15">Write failing /api/v1 request specs: activity wishlist/items CRUD, reserve/extend/cancel, gift paths, my_reservations includes activity holds, open_gifting N setting pre-seal only, error shapes for budget/visibility/limit. Trace [REQ-ACT-005], [REQ-RES-004], [REQ-RES-005], [REQ-ARCH-001].</step>
  <step status="pending" id="16">Implement API controllers/serializers until step 15 green.</step>
  <step status="pending" id="17">Write failing Hotwire request/system specs: activity board list/item/reserve/gift/grace parity; budget errors visible; no activity lists under personal wishlists UI; no Secret Link controls on activity lists. Trace [REQ-ACT-001], FC1A, FC4A.</step>
  <step status="pending" id="18">Implement Hotwire activity B surfaces until step 17 green (DesignTokens defaults).</step>
  <step status="pending" id="19">Write failing Flutter tests: activity list/item forms with price, reserve/gift/grace flows, limit/budget errors, board-only navigation (not My Wishlists), prefs for new events. Trace [REQ-MOB-001], O1B..O6A.</step>
  <step status="pending" id="20">Implement Flutter activity B feature until step 19 green (headless/fakes; no Nata retokenize).</step>
  <step status="pending" id="21">Update living docs required for start-task truth only: API_CONTRACT activity item/reservation surfaces, SYSTEM_ARCHITECTURE B services, BEHAVIOUR_MATRIX planned rows, SPEC notes if needed for activity wishlist rules — with REQ-ID tags. Do not mark ROADMAP Sprint B Done in this plan.</step>
  <step status="pending" id="22">Run full backend RSpec + flutter analyze / flutter test; fix until green. End of start-task implementation scope.</step>
</implementation_plan>
