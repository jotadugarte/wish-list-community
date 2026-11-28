# Explore Session — v1 Sprint A Activities (Configurable System + Exclusions + Blind Dropout Bridge)

**Skill:** explore-task  
**Classification:** Feature  
**Repo:** jotadugarte/wish-list-community  
**Base:** `origin/main` @ `8d76b48` (Merge PR #18 — Sprint 9 brand docs closeout)  
**Started:** 2026-11-28 (America/Costa_Rica)  
**Status:** DISCOVERY COMPLETE (Phase 2 · Step 2.1) — plan **CONFIRMED** (owner 2026-11-27 America/Costa_Rica). Handoff to `start-task` on a **new worker**. No product code from this explore.  
**Durable explore doc:** `/cursor/stores/bc-32a5179f-cc50-4940-94d7-70abc32641c4/docs/explore-v1-sprint-a-activities.md`  
**Owner language:** plain everyday Spanish (“en cristiano”); phone vs web first; short A/B/C; no jargon walls.  
**Out of band:** Ñata visual tokens (WLC-28) — do not wait; no DesignTokens retokenize in this explore.

## Opening triad

### What do we know?
- ROADMAP next backlog item on `origin/main` is **v1 Sprint A — Activities (Configurable System + Exclusions + Blind Dropout Bridge)** (`REQ-ACT-001`..`005`; related `REQ-RES` only as listed under that sprint). Sprint B / Cooperacha / email are **not** in scope unless the owner locks an absorb.
- SPEC §4.6 already defines domain intent: `Activity`, `ActivityParticipant`, `ActivityExclusion`; modes `secret_santa` / `open_gifting`; visibility + reservation visibility settings; 5 `budget_mode`s; min 3 `accepted` for draw; single Hamiltonian cycle; Blind Auto-Bridge vs Full Redraw (`REQ-ACT-001`..`005`). Glossary names `ActivityDropoutBridgeService`.
- Visibility matrix already covers Activity Link guests (scoped to that activity only) and Block Wins on activities (`REQ-WISH-001` / `REQ-BLOCK-001` / `REQ-DISC-001` scenarios).
- Schema readiness: `wishlists.activity_id` + `max_reservations_per_user` exist (`REQ-ARCH-002`); **no** `activities` / participants / exclusions / assignments tables or models yet. No Flutter `activities` feature folder. Sprint 9 locked activity deep links as deferred until v1 (O3A).
- Architecture: Rails server authority; Hotwire + Flutter thin clients; same product options on web and phone (project preference). DesignTokens / Ñata retokenize is a separate track — proceed with defaults.
- **O1A LOCKED:** Sprint A only — no Sprint B / Cooperacha / email absorb.
- **O2B LOCKED:** two-layer freeze — money/visibility @ first accept; who-gifts-whom @ draw; name/dates soft + notice.
- **O3B LOCKED:** creator + co-organizers equal powers (invite / exclusions / draw / dropout recovery).
- **O4B LOCKED:** activity board + bridge to personal wishlists; no activity-scoped lists in A.
- **O5B LOCKED:** opaque activity token URL; safe public preview; logged-in board; App/Universal Links parity.
- **O6A LOCKED:** open_gifting no draw; Arrancar/cerrar altas seals; Blind Bridge only secret_santa; not deferred (not O6D).
- **O7B LOCKED:** free leave before seal; post-draw leave → Bridge/Redraw; post-Arrancar leave no bridge.
- **O8A LOCKED:** full Sprint A activity notification catalog on inbox/email/push + prefs.
- **FC1A LOCKED:** Block Wins mid sealed secret_santa → remove affected + force Bridge/Redraw via creator/co-org.
- **FC2C LOCKED (hybrid):** creator may cancel whole activity and/or transfer ownership to co-org then leave.
- **FC3A LOCKED:** open_gifting Arrancar requires ≥2 accepted participants.
- **ACCEPT parks:** co-org appoint = creator-only; admin must not leak assignments; bounded draw; dormant reservation_visibility until B; DesignTokens later; soft-delete cascade as impl risk.
- Coding standards: acyclomatic ≤10, bounded loops (draw/solvability must be hard-bounded), assertion density, ≤60-line functions; draw RNG must accept deterministic seed in tests (TESTING_STRATEGY_MATRIX).
- Verification: `tdd`. Behaviour matrix file already exists (no re-offer).

### What don't we know?
- ~~Whether Sprint A absorbs Sprint B~~ → **O1A LOCKED:** Sprint A only.
- ~~When activity settings freeze~~ → **O2B LOCKED:** two-layer freeze (money/visibility at first accept; who-gifts-whom at draw; name/dates soft with notice).
- ~~Who may invite / manage exclusions / draw / dropout~~ → **O3B LOCKED:** creator + co-organizers with same powers (invite / exclusions / draw / Blind Bridge vs Full Redraw).
- ~~How activity wishlists/items appear in Sprint A~~ → **O4B LOCKED:** activity board + bridge to personal wishlists (friendship/privacy/Block Wins); no activity-scoped lists in A.
- ~~Exact Activity Link URL / deep links~~ → **O5B LOCKED:** opaque activity share token URL; safe public invite preview; logged-in board; App/Universal Links parity web+app.
- ~~open_gifting draw~~ → **O6A LOCKED:** no draw; Arrancar/cerrar altas seals participation (O2B layer 2); Blind Bridge only for secret_santa. Not O6D (open_gifting stays in A).
- ~~Dropout rules~~ → **O7B LOCKED:** free leave before seal; after secret_santa draw leave forces Blind Bridge or Full Redraw via creator/co-org; after open Arrancar leave without bridge.
- ~~Notification catalog~~ → **O8A LOCKED:** full Sprint A activity notification catalog on existing inbox/email/push + prefs (no Sprint B item/reservation events).
- ~~Block Wins mid-seal secret_santa~~ → **FC1A LOCKED:** Block Wins removes affected participant(s) and forces Blind Bridge or Full Redraw via creator/co-org (same cure path as O7B leave). Creator cancel/transfer → FC2C. Soft-delete cascade detail remains implementation risk unless raised.

### What do we need to define?
- ~~Final check / Domain Model / plan~~ → **CONFIRM PLAN** locked. Launch `start-task` on a **new worker** when ready.

## Classification
**Feature**

## Scope fence (**O1A LOCKED**)
**In (Sprint A):** create/configure activity; invite/accept participants; Block Wins on participation; pair exclusions + solvability; secret_santa Hamiltonian draw; post-draw Blind Auto-Bridge or Full Redraw; external activity link scoped to activity info; configure `budget_mode` + settings (`assignment_mode`, `visibility_mode`, `reservation_visibility`); currency + dates on activity. Same options on Hotwire + Flutter.

**Out (locked):** Sprint B activity item lists, in-activity reservations, budget **enforcement** on items/reservations; Cooperacha; email confirmation; “don’t repeat last year”; price-from-link validation; DesignTokens retokenize.

## Domain Model
_(Feature — firm for plan; O1A..O8A + FC1A + FC2C + FC3A + ACCEPT parks)_

**Confirmed for start-task (hands-off) 2026-11-27 America/Costa_Rica:** Activity, ActivityParticipant, ActivityCoOrganizer, ActivityExclusion, ActivityAssignment, BudgetMode, ActivityLinkToken, ActivitySeal, BlindBridgeResult — no adds/renames/removes.

| Entity / VO | Responsibility | Invariants |
| :--- | :--- | :--- |
| **Activity** | Group exchange: creator, name, dates, single currency, `assignment_mode`, `visibility_mode`, `reservation_visibility`, `budget_mode` + bounds, share token, seal state | One currency; O2B freezes; Block Wins deny; cancel ends activity (FC2C) |
| **ActivityParticipant** | Invite / accept / decline / leave; optional co-org flag | Blocks prevent join; ≥3 accepted for secret_santa draw; ≥2 for open Arrancar (FC3A); free leave pre-seal (O7B) |
| **ActivityCoOrganizer** | Same admin powers as creator except appoint/remove co-orgs and ownership transfer target rules | Only **creator** appoints/removes co-orgs (ACCEPT parks); co-org cannot demote creator; transfer ownership → former creator may leave (FC2C) |
| **ActivityExclusion** | “A cannot gift B” for secret_santa | Solvability before draw and before Blind Bridge; freeze at draw (O2B) |
| **ActivityAssignment** | Post-draw giver→recipient edge | Single Hamiltonian cycle; never exposed wholesale to creator/co-org/admin |
| **BudgetMode** (VO) | `none`/`fixed`/`min_only`/`max_only`/`range` + bounds | Stored in A; **not** enforced on items/reservations until Sprint B |
| **ActivityLinkToken** (VO) | Opaque share token | Public preview safe (no roster); login for board; App/Universal Links (O5B) |
| **ActivitySeal** (VO/state) | secret_santa = draw committed; open_gifting = Arrancar | Triggers O2B layer-2 freeze |
| **BlindBridgeResult** (VO) | Heal `A→B→C` → `A→C` | Notify giver only; validate exclusions (REQ-ACT-003/004) |

## Decision log

### O1 — Sprint boundary: ¿absorbemos Sprint B / Cooperacha / email? — **LOCKED A** (owner 2026-11-27 America/Costa_Rica)
Sprint A only: create group activity, invitations, exclusions, draw/Secret Santa, Blind Auto-Bridge / Full Redraw. No Sprint B lists/reservations/budget enforcement; no Cooperacha; no email confirmation.

### O2 / O2′ — ¿Hasta cuándo se pueden editar las reglas (equidad)? — **LOCKED B** (owner 2026-11-27 America/Costa_Rica)
Two-layer freeze:
1. On first invite **accept**: freeze currency, budget, and visibility modes that affect spend/expectations.
2. On **draw**: freeze who-gifts-whom (assignment type, exclusions, draw result).
Soft fields (name/dates) editable with notice. Post-draw recovery remains Blind Auto-Bridge or Full Redraw only.

### O3 — ¿Quién administra invitaciones, exclusiones, sorteo y dropout? — **LOCKED B** (owner 2026-11-27 America/Costa_Rica)
Creator + co-organizers with the **same** powers: invite, exclusions, draw, and dropout Blind Auto-Bridge vs Full Redraw. Same on Hotwire + Flutter. (How many co-orgs / who can appoint — implementation detail unless a later card needs it; default: creator appoints/removes co-organizers.)

### O4 — En Sprint A sin listas de regalos: ¿qué ve un participante el día uno? — **LOCKED B** (owner 2026-11-27 America/Costa_Rica)
Activity board (rules, people, exclusions, draw UX) + bridge to existing **personal** wishlists when friendship/visibility allow; respect Block Wins. No activity-scoped wishlists/item lists in Sprint A (those stay Sprint B).

### O5 — Forma del enlace de actividad + deep link — **LOCKED B** (owner 2026-11-27 America/Costa_Rica)
Opaque activity share-token URL; safe public invite preview (no private roster leak); logged-in activity board; App/Universal Links open the app when installed, else Hotwire — same token both surfaces (REQ-ACT-001).

### O6 — open_gifting en Sprint A: ¿hay “sorteo”? — **LOCKED A** (owner 2026-11-27 America/Costa_Rica)
open_gifting: **no draw**. Creator/co-org uses **Arrancar / cerrar altas** to seal participation (= O2B layer-2 freeze for open_gifting). Blind Auto-Bridge / Full Redraw **only** for `secret_santa`. **Not O6D** — open_gifting remains in Sprint A (shell without activity lists until B).

### O7 — Salida / abandono antes y después del sello (sorteo o Arrancar) — **LOCKED B** (owner 2026-11-27 America/Costa_Rica)
Before seal: any participant may leave freely. After **secret_santa** draw: leave notifies and **forces** creator/co-org to choose Blind Auto-Bridge or Full Redraw (no broken cycle). After **open_gifting** Arrancar: leave allowed **without** bridge. Same on Hotwire + Flutter.

### O8 — ¿Qué avisos nuevos entran en Sprint A? — **LOCKED A** (owner 2026-11-27 America/Costa_Rica)
Full Sprint A activity notification catalog on existing NotificationDispatcher (in-app + email + push) + per-event prefs: invite, accept/decline, co-org changes, draw (private recipient to giver), Arrancar/cerrar altas, leave, dropout needs cure, Blind Bridge (affected giver only), Full Redraw. No Sprint B activity item/reservation notification events.

### Candidate later cards (not presented yet)
_(none material — Final check)_

### FC1 — Block Wins a mitad de amigo secreto ya sorteado — **LOCKED A** (owner 2026-11-27 America/Costa_Rica)
Mid-draw/sealed secret_santa Block Wins removes the affected participant(s) from the activity and **forces** creator/co-org to choose Blind Auto-Bridge or Full Redraw (same family of cure as O7B leave). Open_gifting: remove affected; no bridge (no cycle).

### FC2 — Creator cancel / leave — **LOCKED C (hybrid)** (owner 2026-11-27 America/Costa_Rica)
Creator can **cancel** the whole activity (notify participants) **and** can **transfer ownership** to an existing co-org then leave. Both powers ship in Sprint A. Same on Hotwire + Flutter.

### FC3 — Mínimo aceptados para Arrancar (regalos abiertos) — **LOCKED A** (owner 2026-11-27 America/Costa_Rica)
open_gifting **Arrancar / cerrar altas** requires ≥2 `accepted` participants. secret_santa draw remains ≥3 per SPEC.

### ACCEPT parks — **LOCKED** (owner 2026-11-27 America/Costa_Rica)
Parked Final-check risks accepted: creator-only co-org appoint/remove; no admin leak of assignment map; hard-bounded Hamiltonian/exclusion solvability; `visibility_mode`/`reservation_visibility` stored in A, enforced in B; DesignTokens/Ñata out of band; soft-delete activity cascade aligned with Block Wins as implementation risk (no extra product card).

### Candidate later cards (not presented yet)

## Dark corners & pitfalls
_(Final check — Step 1.3, 2026-11-27 America/Costa_Rica)_

### Edges / pitfalls (documented)
1. **Blind Bridge secrecy:** Creator/co-org must never see the full assignment map via API, Hotwire, Flutter, or admin gift-detail habits from personal lists. Bridge notifies only the affected giver.
2. **O2B layer-2 trigger differs by mode:** secret_santa → draw; open_gifting → Arrancar/cerrar altas (O6A). Soft name/dates still editable with notice.
3. **Budget modes stored, not enforced in A:** UI can set `budget_mode` + bounds; enforcement waits Sprint B — copy must not promise “blocked checkout” yet.
4. **`visibility_mode` / `reservation_visibility`:** SPEC settings at create; with no activity lists/reservations in A, they are mostly dormant until B — still collect at create so B inherits (avoid re-asking).
5. **Personal-wishlist bridge (O4B):** Not a spoiler channel for secret_santa assignments beyond “my recipient’s visible lists”; Block Wins / friendship / list visibility still gate.
6. **Hamiltonian + exclusions:** Must be hard-bounded (coding standards); unsolvable graph → clear refuse before commit; same before Blind Bridge.
7. **Post-draw leave with <3 accepted left:** Full Redraw may be impossible; may need cancel activity or force open-mode collapse — see FC3-ish / risk.
8. **Co-org vs creator:** O3B equal powers; appoint/remove default = creator only (parked unless FC says otherwise). Co-org cannot demote creator.
9. **Block mid-activity / soft-delete:** Must align Block Wins; sealed secret_santa needs cure path — **FC1**.
10. **Creator abandons:** Cancel whole activity vs forced transfer — **FC2**.
11. **open_gifting Arrancar minimum:** **FC3A** ≥2 accepted (secret_santa draw still ≥3).
12. **Ñata / DesignTokens:** out of band; defaults OK.
13. **Email confirmation / Cooperacha:** out of scope (O1A).

### Open items for owner (answer, park, or risk)
- **FC1** — Block Wins after seal — **LOCKED A** (owner 2026-11-27 America/Costa_Rica): mid-activity Block Wins removes affected participant(s) and forces creator/co-org Blind Auto-Bridge or Full Redraw (aligned with O7B post-draw leave cure).
- ~~Creator cancel / leave~~ → **FC2C LOCKED (hybrid).**
- **FC3** — Minimum for open_gifting Arrancar — **LOCKED A** (owner 2026-11-27 America/Costa_Rica): ≥2 accepted.
- **ACCEPT parks** (owner 2026-11-27): admin no assignment leak; bounded draw; dormant reservation_visibility until B; co-org appoint/remove = creator only (co-org cannot demote creator); DesignTokens later; soft-delete cascade detail = implementation risk with Block Wins alignment.

## Implementation risks (parked)
- Post-draw roster can drop below 3 accepted — product may need cancel if redraw impossible (tie FC3 / implementation guard).
- Co-organizer appoint/remove: default creator-only until FC says otherwise; co-org cannot remove creator.
- `visibility_mode` / `reservation_visibility` collected in A, enforced in B — risk of owner confusion if UI over-promises.
- O2′ fairness: Sprint A cannot reliably detect “bought for this activity” on personal wishlists without ambiguous coupling; prefer explicit freeze triggers (accept / draw) over purchase-detection.
- Hamiltonian + exclusion solvability must stay hard-bounded (coding standards Rule 2) — algorithm choice is implementation detail once product locks.
- Blind bridge must not leak assignments to creator via API, Hotwire, or admin peek (admin gift detail exists for personal lists — need explicit activity policy later).
- `wishlists.activity_id` ready but item/reservation flows are Sprint B — O4B board+personal bridge only; do not half-wire activity lists.

## Lock checklist (Step 1.4)
- [x] Opening triad recorded
- [x] Classification: **Feature**
- [x] Domain Model populated (Feature)
- [x] Final check done (FC1A, FC2C, FC3A, ACCEPT parks)
- [x] Dark corners recorded
- [x] Every open question answered, deferred, or implementation risk
- [x] Behaviour matrix: already exists (`docs/core/BEHAVIOUR_MATRIX.md`) — no re-offer
- [x] `<implementation_plan>` inserted (TDD only; no finish-branch / PR / QA / merge steps)
- [x] Owner **CONFIRM PLAN** (2026-11-27 America/Costa_Rica)

## Dual-client surfaces (Sprint A)
Hotwire + Flutter parity for: create/configure activity; invite/accept/decline/leave; co-org (creator appoints); exclusions; draw / Arrancar; Blind Bridge / Full Redraw; cancel; transfer ownership; activity share link (web preview + App Links); board + personal wishlist bridge; notification prefs for new events.

REQ tags: `REQ-ACT-001`..`005`, `REQ-ARCH-001`/`002`, `REQ-BLOCK-001`, `REQ-NOTIF-001`/`002`, `REQ-MOB-001` (activity deep links), related visibility `REQ-WISH-001` / `REQ-DISC-001` scenarios for activity link.

<implementation_plan>
  <step id="1" status="complete">Write failing model/migration specs for `Activity` (+ BudgetMode VO validations for five modes), `ActivityParticipant` (invite/accept/decline/leave, co-org flag), unique constraints, and opaque `ActivityLinkToken`. Trace [REQ-ACT-001], [REQ-ACT-005], [REQ-ARCH-001].</step>
  <step id="2" status="complete">Implement schema + models minimally until step 1 green (no UI yet).</step>
  <step id="3" status="complete">Write failing specs for O2B freeze: on first accept lock currency/budget/visibility modes; soft name/dates remain editable with audit/notice hook. Trace [REQ-ACT-001].</step>
  <step id="4" status="complete">Implement freeze rules until step 3 green.</step>
  <step id="5" status="complete">Write failing Pundit/policy + Block Wins specs: blocked users cannot join/view board; mid sealed secret_santa block removes affected and requires cure (FC1A); open_gifting removes without bridge. Trace [REQ-BLOCK-001], [REQ-ACT-003].</step>
  <step id="6" status="complete">Implement Activity policies + block cascade hooks until step 5 green.</step>
  <step id="7" status="complete">Write failing specs for creator-only co-org appoint/remove (ACCEPT parks), equal admin powers for invite/exclusions/draw/dropout/Arrancar (O3B), ownership transfer + cancel (FC2C). Trace [REQ-ACT-001], [REQ-ACT-003].</step>
  <step id="8" status="complete">Implement co-org / transfer / cancel services until step 7 green.</step>
  <step id="9" status="complete">Write failing specs for `ActivityExclusion` + bounded deterministic solvability validation (hard upper bound). Trace [REQ-ACT-002], [REQ-ACT-004].</step>
  <step id="10" status="complete">Implement exclusions + solvability until step 9 green.</step>
  <step id="11" status="complete">Write failing specs for secret_santa draw: ≥3 accepted; single Hamiltonian cycle; deterministic seed in tests; persists `ActivityAssignment` without exposing full map to creator. Trace [REQ-ACT-001], [REQ-ACT-004].</step>
  <step id="12" status="complete">Implement `ActivityDrawService` (seedable RNG) until step 11 green.</step>
  <step id="13" status="complete">Write failing specs for open_gifting Arrancar/cerrar altas: ≥2 accepted (FC3A); no assignments; seals participation (O6A/O2B layer-2). Trace [REQ-ACT-001].</step>
  <step id="14" status="complete">Implement Arrancar seal until step 13 green.</step>
  <step id="15" status="complete">Write failing specs for leave (O7B): free pre-seal; post-draw leave forces Blind Bridge or Full Redraw choice; post-Arrancar leave without bridge; Blind Bridge validates exclusions and notifies only giver. Trace [REQ-ACT-003], [REQ-ACT-004].</step>
  <step id="16" status="complete">Implement leave + `ActivityDropoutBridgeService` + Full Redraw until step 15 green (guard when &lt;3 remain: refuse redraw / require cancel — implementation risk).</step>
  <step id="17" status="complete">Write failing request specs for `/api/v1` activity CRUD, participants, exclusions, draw/Arrancar, bridge/redraw, cancel/transfer, show assignment only to giver. Trace [REQ-ACT-001]..[005], [REQ-ARCH-001].</step>
  <step id="18" status="complete">Implement API controllers/serializers until step 17 green (no activity item/reservation endpoints — O1A).</step>
  <step id="19" status="complete">Write failing request/system specs for Hotwire: public activity invite preview by token (safe OG, no roster); logged-in board; create/manage flows parity with API rules; personal wishlist bridge links when allowed (O4B/O5B). Trace [REQ-ACT-001], [REQ-WISH-001].</step>
  <step id="20" status="complete">Implement Hotwire activity surfaces until step 19 green.</step>
  <step id="21" status="complete">Write failing specs for NotificationDispatcher catalog keys (O8A): invite, accept/decline, co-org, draw (private), Arrancar, leave, dropout-needs-cure, Blind Bridge, Full Redraw, cancel, transfer — prefs toggles. Trace [REQ-NOTIF-001], [REQ-NOTIF-002].</step>
  <step id="22" status="complete">Implement notification events + prefs until step 21 green.</step>
  <step id="23" status="complete">Write failing Flutter tests for activity feature: board, invite/accept, exclusions UI for co-org/creator, draw/Arrancar, private recipient, leave/cure prompts, cancel/transfer; personal wishlist bridge. Trace [REQ-ACT-001]..[005], [REQ-MOB-001].</step>
  <step id="24" status="complete">Implement Flutter activities feature until step 23 green (headless/fakes; DesignTokens defaults — no retokenize).</step>
  <step id="25" status="complete">Write failing Flutter DeepLinkTarget tests: activity share token opens board/preview; unknown safe failure; keep friend + secret link. Trace [REQ-MOB-001], [REQ-ACT-001].</step>
  <step id="26" status="complete">Implement activity App/Universal Links + routing until step 25 green.</step>
  <step id="27" status="complete">Update living docs only as needed for start-task truth: API_CONTRACT new activity surfaces, SYSTEM_ARCHITECTURE activity services, BEHAVIOUR_MATRIX planned rows for ACT flows, ROADMAP Sprint A checkboxes stay unchecked in this plan (Done marking is outside start-task). Trace REQ-IDs in new tests.</step>
  <step id="28" status="complete">Run full backend RSpec + `flutter analyze` / `flutter test`; fix until green. End of start-task implementation scope.</step>
</implementation_plan>

**PLAN CONFIRMED** by owner 2026-11-27 (America/Costa_Rica). Spec locked for `start-task` handoff. This explore writes no application code.
