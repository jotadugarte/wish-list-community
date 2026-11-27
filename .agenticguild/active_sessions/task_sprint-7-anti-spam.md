---
cursor:
  subagentId: "bc-d4d897ba-f73b-5382-80d7-b04ea0cac27a"
---

<task_session>
  <metadata>
    <task_name>MVP Sprint 7 — Anti-Spam, Rate Limits & Wishlist Reports</task_name>
    <type>Feature</type>
    <req_id>REQ-DISC-001</req_id>
    <roadmap_item>MVP Sprint 7 — Anti-Spam, Rate Limits & Wishlist Reports</roadmap_item>
    <base_sha>34dbf94 (origin/main — Merge PR #13 Sprint 6 Dual-Path Gifts)</base_sha>
    <living_doc>/cursor/stores/bc-32a5179f-cc50-4940-94d7-70abc32641c4/docs/sprint-7-anti-spam-explore.md</living_doc>
  </metadata>

  <execution_context>
    <active_skill>start-task</active_skill>
    <current_phase>3</current_phase>
    <current_step>3.2 Step 8 — Hotwire rate_limit declarations</current_step>
    <awaiting>hands-off TDD in progress</awaiting>
  </execution_context>

## Classification
**Feature**

## Process preferences (durable)
- Decision cards **one at a time** with recommendation; never batch O*.
- Plain concrete language (who sees what / what ships) before options.
- Letter quick-replies **A/B/C**.
- Full **web + Flutter** parity for every feature/option (owner prefs 2026-11-26).
- No product code / no `start-task` until owner says `start-task`.
- Hands-off only for later `start-task` (config `start_task_mode: hands-off`).

## Anchors already locked (carry forward / prefs / roadmap)
| ID | Decision |
| :--- | :--- |
| **S6 done** | Dual-path gifts merged PR #13 on `main` @ `34dbf94` (2026-11-26). |
| **Client parity** | Every S7 feature option ships on **web (Hotwire) and Flutter** — same capabilities. |
| **Admin UI = S8** | Reviewing/acting on the reports queue (block/suspend, audit viewer) stays **Sprint 8**. S7 only **creates** pending reports into the existing queue. |
| **Report foundation** | Polymorphic `Report` + `ReportReason` VO + duplicate-pending unique index + `AuditEvent` `"report.created"` + `POST /api/v1/reports` already ship for **User** only (`ALLOWED_REPORTABLE_TYPES` = User). Model comments already name Wishlist as Sprint 7. |
| **Rate limit today** | Rails 8 `rate_limit` on auth (login/signup/passwords), account restore, and link-preview create. **No** rate_limit yet on friendships, reports, wishlists, items, reservations, gifts, blocks, etc. |
| **Flutter report UX** | Report **user** exists on search/friends screens. **No** wishlist report UI. **No** Hotwire report UI at all today. |
| **O1A** | Wishlist report allowed for any **logged-in viewer** with access (friends / shared / Secret Link), **except owner**. Guests must log in. Block wins. Locked owner 2026-11-26. |
| **O2A** | `rate_limit` on **all write mutations** (API + Hotwire) + reports; keep existing auth/preview caps; ~10–30/few minutes; clear 429 UX on web + Flutter. Locked owner 2026-11-26. |
| **O3A** | Report wishlist UI: Flutter wishlist detail (non-owner) + Hotwire authenticated Secret Link (non-owner); same ReportReason; confirm + 429; web Report user out of S7. Locked owner 2026-11-26. |
| **O4A** | Report only if currently viewable (O1A). Soft-deleted / invalid link / blocked / no access → no new report, "unavailable". Existing pending reports stay for S8. Locked owner 2026-11-26. |
| **O5A** | Post-report = enqueue `pending` + AuditEvent only (same as user reports). No auto-hide, no owner notify, no admin email in S7. Triage = S8. Locked owner 2026-11-26. |
| **FC1 KEEP** | All 5 `ReportReason` values apply to wishlist reports. Locked Final check 2026-11-26. |
| **FC2 OK / R1** | Exact `rate_limit` numbers are implementation tuning within O2A ~10–30 / few minutes band. Locked Final check 2026-11-26. |
| **FC3 NONE** | No further dark corners. Locked Final check 2026-11-26. |
| **REQ-DISC-001** | Anti-stalking profile search + wishlist report system with Rails 8 `rate_limit` anti-spam protection. |

## Opening triad
**What we know:** Sprint 6 is on main. Reporting a **user** already works end-to-end (API + Flutter). The polymorphic `Report` model is ready for Wishlist. Sprint 7 roadmap asks for (1) `rate_limit` on mutation + report endpoints, (2) report wishlist, (3) sensitive content goes through the reports queue, (4) API + Flutter (and prefs require Hotwire parity too). Admin triage is Sprint 8.

**What we don't know:** *(none material — see Final check)*

**What we need to define:** Lock owner decisions (O1…) → Final check → implementation plan → explicit `start-task` (no coding in this explore).

## Decision cards

### O1 — Quién puede reportar una wishlist — **LOCKED A** (owner 2026-11-26)
Any logged-in viewer with wishlist access (except owner) can report. Guests must log in. Block wins. Cannot report a list you cannot see.

### O2 — Alcance del rate_limit anti-spam — **LOCKED A** (owner 2026-11-26)
All write mutations (API + Hotwire) + reports get rate_limit; auth/preview kept; ~10–30/few min; clear 429 on web + Flutter.

### O3 — Dónde aparece Reportar lista (web + app) — **LOCKED A** (owner 2026-11-26)
Flutter wishlist detail + Hotwire authenticated Secret Link (non-owner); same reasons; confirm + 429; web Report user out of S7.

### O4 — Listas borradas / enlace inválido al reportar — **LOCKED A** (owner 2026-11-26)
Report only while currently viewable; soft-deleted/invalid/blocked → unavailable; existing pending stay for S8.

### O5 — Qué pasa después de reportar (contenido sensible) — **LOCKED A** (owner 2026-11-26)
Enqueue pending + AuditEvent only; no auto-hide / owner notify / admin email; triage = S8.

## Dark corners & pitfalls
- **ReportPolicy must enforce O1A viewability** for Wishlist (today `create?` is almost always true for any non-self User target) — easy to wire Wishlist without the visibility check.
- **Hotwire report POST** needs a CSRF cookie-session route (or form) mirroring API; guests on `/s/...` still must log in first (O1A).
- **429 UX** on every mutated Flutter/Hotwire flow (O2A) is broad — miss a controller and spam path remains open; treat “declaration + request spec per write action” as the verification bar.
- **Duplicate pending** already blocks a second pending report on the same wishlist; reporter should see a clear “already reported” style error (same family as user reports).
- **`impersonation` reason on a wishlist** is odd but keeping the same 5 reasons avoids a second VO; park as product quirk unless owner objects in Final check (FC1).
- **Soft-deleted wishlist restore** with a still-pending report is fine (O4A); admin in S8 may see a live list again — document, don’t auto-dismiss.
- **Exact numeric caps** (~10–30 / few minutes) left as implementation tuning within O2A ballpark — not a product fork (risk R1).
- **Report user on Hotwire** explicitly out of S7 (O3A) — do not sneak it into the plan.
- **Admin UI / hide / suspend** must not leak into S7 plan (O5A + Admin=S8).

## Final check — **ACCEPTED** (FINAL OK; FC1 KEEP + FC2 OK + FC3 NONE; owner 2026-11-26)
FC1: Keep all 5 `ReportReason` values for wishlist (including `impersonation`), or subset? Rec: keep all 5.
FC2: Accept R1 (exact rate_limit numbers as implementation tuning in O2A band) without another card?
FC3: Any other dark corner to lock, park, or risk?

## Domain Model (updated)
- **Report**: User (existing) + Wishlist (S7). Invariants: O1A viewability; cannot report own wishlist; O4A no report if not currently visible; duplicate pending; O5A enqueue-only; AuditEvent.
- **ReportReason**: same VO for both targets (pending FC1).
- **Rate limits**: Rails 8 controller `rate_limit` on all writes (O2A); not a domain entity.


## Domain Model
See updated Domain Model block under Final check section above (O1A–O5A locked).

## Working notes
- Next pending after S6 = **Sprint 7** (roadmap). Sprint 8 = Admin/Moderation web-only.
- Explore must not write product code.

  <implementation_plan>
    <step id="1" status="complete">Write failing RSpec for Wishlist abuse-report domain rules: `ReportPolicy#create?` allows only when reporter can `WishlistPolicy#show?` and is not the owner (O1A); denies soft-deleted / no-access / blocked (O4A); `Report.submit!` accepts `reportable: Wishlist` with all 5 `ReportReason` values (FC1 KEEP); duplicate pending rejected; AuditEvent `report.created` recorded; no owner Notification created (O5A). Trace `[REQ-DISC-001]`, `[REQ-ADM-001]`, `[REQ-WISH-001]`, `[REQ-BLOCK-001]`.</step>
    <step id="2" status="complete">Implement the minimal domain/policy changes to make step 1 green (extend `Report` / `ReportPolicy` for Wishlist; reuse existing VO + pending unique index). No new controllers yet.</step>
    <step id="3" status="complete">Write failing request specs for `POST /api/v1/reports` with `reportable_type: "Wishlist"`: happy path for friend / sharee; owner rejected; stranger/blocked/soft-deleted → unavailable (404/422 aligned with existing patterns); duplicate pending error; response shape matches user reports; declare `rate_limit` on `ReportsController#create`. Trace `[REQ-DISC-001]`, `[REQ-ARCH-003]`.</step>
    <step id="4" status="complete">Implement API wiring until step 3 green: add `Wishlist` to `ALLOWED_REPORTABLE_TYPES`; resolve only non-discarded wishlists; authorize via updated policy; keep thin controller.</step>
    <step id="5" status="complete">Write failing specs that assert Rails 8 `rate_limit` is declared on every API v1 **write** action lacking it today (friendships create/update/destroy, user_blocks create, wishlists create/update/destroy/rotate, wishlist_shares create/destroy, items create/update/destroy/destroy_image, reservations create/update/destroy, gifts/reservation_gifts/item_gifts creates, notification_preferences update, sessions destroy, accounts destroy, reports create) within O2A/R1 band (~10–30 per few minutes). Keep existing auth/preview/restore caps unchanged. Trace `[REQ-DISC-001]`.</step>
    <step id="6" status="complete">Add the missing API `rate_limit` declarations until step 5 green (no behavior change beyond 429 when exceeded).</step>
    <step id="7" status="complete">Write failing specs declaring `rate_limit` on Hotwire mutation controllers (Secret Link reservations/gifts mark-purchased/delivered/confirm/mark-received, and any other cookie-session write actions that mutate state) in the same O2A/R1 band. Trace `[REQ-DISC-001]`.</step>
    <step id="8" status="pending">Implement Hotwire `rate_limit` declarations until step 7 green.</step>
    <step id="9" status="pending">Write failing request/system specs for Hotwire **Reportar lista** on authenticated Secret Link show (O3A): non-owner sees report control + same 5 reasons; CSRF POST creates pending report; guest must log in (`return_to`); owner sees no control; soft-deleted/invalid token → unavailable (O4A); exceeding limit shows wait message (429); no notification to wishlist owner (O5A). Trace `[REQ-DISC-001]`, `[REQ-WISH-002]`, `[REQ-AUTH-001]`.</step>
    <step id="10" status="pending">Implement Hotwire report UI + thin web reports controller/route until step 9 green (cookie session + CSRF; reuse `Report.submit!`).</step>
    <step id="11" status="pending">Write failing Flutter tests for wishlist report on `WishlistDetailScreen` (non-owner): reason picker (5 values), success confirmation, duplicate/unavailable/429 messaging, bilingual `AppStrings`; repository posts `reportable_type: Wishlist`. Trace `[REQ-DISC-001]`.</step>
    <step id="12" status="pending">Implement Flutter repository/UI/strings until step 11 green. Do **not** add Hotwire Report-user (explicitly out of S7 per O3A).</step>
    <step id="13" status="pending">Update in-repo docs as part of the feature: `docs/core/API_CONTRACT.md` Wishlist reportable + rate_limit notes; touch `docs/core/SPEC.md` / SCHEMA / DATA_FLOW only if wording must reflect Wishlist reports + mutation rate limits; leave ROADMAP Sprint 7 checkboxes for verified Done during later sync/finish (do not claim Done here). No Admin UI. No ADR unless an architecture boundary is violated.</step>
    <step id="14" status="pending">Run full `backend` RSpec + RuboCop and `mobile` `flutter analyze` / `flutter test`; fix failures until green. End of `start-task` implementation scope.</step>
  </implementation_plan>
</task_session>

## Lock checklist — **PASS** (step 1.4)
- Opening triad recorded
- Classification: Feature
- Domain Model populated (Report + Wishlist reportable + ReportReason; rate_limit enforcement)
- Final check done (FINAL OK)
- Dark corners recorded
- All opens answered / deferred / risk (O1A–O5A, FC1–FC3, R1)
- Behaviour matrix already exists (`docs/core/BEHAVIOUR_MATRIX.md`) — offer skipped
- `<implementation_plan>` written (14 TDD steps; ends at local green suites)

## Handoff status — **COMPLETE**
- Plan **confirmed** (CONFIRM PLAN). Phase 2 validation: Feature TDD (failing-test steps 1/3/5/7/9/11), architecture OK (Rails rate_limit + Pundit + polymorphic Report + Hotwire/Flutter clients; Admin stays S8), no wrapping steps in plan.
- Spec **locked**. Archive-ready explore session.
- **Next:** coordinator/owner runs **`start-task`** (hands-off) on a **new worker**. This explore agent does **not** write product code.

