---
cursor:
  subagentId: "bc-4cc12df6-8f99-5f8d-8eb9-e87ede9e1830"
---

<task_session>
  <metadata>
    <task_name>MVP Sprint 8 — Admin/Moderation (Web Only)</task_name>
    <type>Feature</type>
    <req_id>REQ-ADM-001</req_id>
    <roadmap_item>MVP Sprint 8 — Admin/Moderation (Web Only)</roadmap_item>
    <base_sha>c6ead7e (origin/main — Merge PR #14 Sprint 7 Anti-Spam)</base_sha>
    <living_doc>/cursor/stores/bc-32a5179f-cc50-4940-94d7-70abc32641c4/docs/sprint-8-admin-moderation-explore.md</living_doc>
  </metadata>

  <execution_context>
    <active_skill>start-task</active_skill>
    <current_phase>3</current_phase>
    <current_step>3.3 — Phase 3 complete; await QA/finish-branch</current_step>
    <awaiting>Owner QA? / finish-branch?</awaiting>
  </execution_context>

## Classification
**Feature**

## Process preferences (durable)
- Decision cards **one at a time** with recommendation; never batch O*.
- Plain concrete language (who sees what / what ships) before options.
- Letter quick-replies **A/B/C**.
- Full **web + Flutter** parity for every **member-facing** feature/option (owner prefs 2026-11-26); Admin stays **Web Only** (**O1A** locked 2026-11-26).
- Explain review/compliance findings plainly later (not in explore).
- No product code / no `start-task` until owner says `start-task`.
- Hands-off only for later `start-task` (config `start_task_mode: hands-off`).

## Anchors already locked (carry forward / prefs / roadmap)
| ID | Decision |
| :--- | :--- |
| **S7 done** | Anti-spam + Wishlist reports merged PR #14 on `main` @ `c6ead7e` (2026-11-26). |
| **REQ-ADM-001** | Web-only Admin panel backed by immutable `AuditEvent` — review reports, block abusive accounts, inspect history, revert erroneous/abusive state changes. |
| **Architecture** | `SYSTEM_ARCHITECTURE`: backend includes **Web-only Admin Panel**; DATA_FLOW maps **Admin Audit View (Web Only)** for full Reservation / GiftRecord / purchase link / AuditEvent history. |
| **Report queue ready** | Polymorphic `Report` for `User` + `Wishlist`; statuses `pending` / `reviewed` / `dismissed`; enqueue-only from S2/S7; **no** admin triage UI yet. |
| **Audit foundation** | Immutable `AuditEvent.record!` already used for blocks, friendships, reports, soft-deletes, reservations, gifts. |
| **Role column** | `users.role` is `"user"` or `"admin"`; no Admin controllers/UI yet. **O2A** adds Suspend flag + admin soft-delete path. |
| **Sensitive fields** | `purchase_link_ref` and gifter identity are admin-audit-only today (never in owner/friend API JSON); GiftRecord already allows admin viewer for `gifter_id`. |
| **Next after S8** | Sprint 9 Mobile wrap-up; separate Notifications MVP item remains pending. |
| **Client parity pref** | Full web + Flutter for **member** features; Admin is the Web-only exception. |
| **O1A** | Admin surface = **Web-only Hotwire** panel (cookie session + `role=admin`). No Flutter Admin in Sprint 8. No ADR. Locked owner 2026-11-26. |
| **O2A** | Report-queue actions: **Dismiss** (`dismissed`) + **Suspend** (login ban web+API; content stays until hide decision) + **Admin soft-delete** (account and/or reported wishlist via SoftDeletable). Member `UserBlock` unchanged. Acting marks `reviewed` + AuditEvents. Locked owner 2026-11-26. |
| **O3A** | Suspend does **not** hide content. Only soft-delete (admin or owner) removes from the graph. `reviewed`/`dismissed` never auto-hide. Locked owner 2026-11-26. |
| **O4A** | Audit viewer + 1-click revert **only** for S8 moderation: unsuspend; restore admin soft-delete (within SoftDeletable window); optional reopen `dismissed`→`pending`. Compensating action + new AuditEvent (never mutate old rows). No domain replay of reservations/gifts/friendships/member UserBlocks. Locked owner 2026-11-26. |
| **O5A** | Hotwire Admin shows gifter identity (`@username` + admin-only email) and `purchase_link_ref` (when present) in **read-only** gift/item/AuditEvent detail context. Never in member API/Flutter. No global gift export table. Locked owner 2026-11-26. |
| **O6A** | No in-app admin promotion UI in S8. First/ongoing admins via documented seed / rails console / ops setting `role=admin`. Demote same channel. Locked owner 2026-11-26. |
| **O7A** | No triage/enforcement notifications in S8 (not reporter, not target). AuditEvent + admin state only. Notifications MVP stays separate. Locked owner 2026-11-26. |
| **FC1 KEEP** | Reopen `dismissed`→`pending` is in-scope 1-click revert. Locked Final check 2026-11-26. |
| **FC2 GENERIC** | Suspended login/API auth failures use the same **generic** failure copy as bad credentials (web + API). Locked Final check 2026-11-26. |
| **FC3 SAME** | Admin soft-delete uses the same **30-day SoftDeletable** restore window as self-serve. Locked Final check 2026-11-26. |
| **R1** | Suspend **immediately revokes** sessions + API tokens (+ device_tokens unbound via existing hooks). Locked Final check 2026-11-26. |
| **FINAL OK** | Owner FINAL OK (FC1 KEEP, FC2 GENERIC, FC3 SAME, R1) 2026-11-26. |

## Opening triad
**What we know:** **O1A–O7A** locked. Web-only Admin; Dismiss+Suspend+Admin soft-delete; Suspend no hide; moderation-only 1-click revert; gifter/link read-only detail; ops-only provisioning; no triage notifications.

**What we don't know:** *(none material — see Final check)*

**What we need to define:** CONFIRM PLAN → explicit `start-task` on a new worker (no coding in this explore).

## Decision cards

### O1 — Admin surface channel — **LOCKED A** (owner 2026-11-26)
Web-only Hotwire Admin panel for `role=admin`. No Flutter Admin in S8. Architecture / REQ-ADM-001 stand; no ADR.

### O2 — Moderation actions from the report queue — **LOCKED A** (owner 2026-11-26)
Dismiss + Suspend (login ban web+API) + Admin soft-delete (account and/or reported wishlist). Member UserBlock unchanged. Reports → `reviewed`/`dismissed` + AuditEvents.

### O3 — Content visibility after Suspend / triage — **LOCKED A** (owner 2026-11-26)
Suspend does not hide. Only soft-delete removes content. `reviewed`/`dismissed` never auto-hide.

### O4 — 1-click revert scope (audit viewer) — **LOCKED A** (owner 2026-11-26)
Moderation-only revert: unsuspend; restore admin soft-delete (window); optional reopen dismissed→pending. Compensating + new AuditEvent. No reservation/gift/friendship/UserBlock replay.

### O5 — Admin audit of gifter identity + purchase link — **LOCKED A** (owner 2026-11-26)
Read-only gifter `@username` + admin email + `purchase_link_ref` in gift/item/AuditEvent detail. No member leak. No global export table.

### O6 — Admin provisioning — **LOCKED A** (owner 2026-11-26)
No promotion UI. Admins via seed/console/ops (`role=admin`). Demote same channel.

### O7 — Notifications on triage / enforcement — **LOCKED A** (owner 2026-11-26)
No triage notifications to reporter or target in S8. Admin + AuditEvent only.

## Final check — **ACCEPTED** (FINAL OK; FC1 KEEP + FC2 GENERIC + FC3 SAME + R1; FC4 NONE; owner 2026-11-26)
FC1 KEEP: reopen dismissed→pending in-scope.
FC2 GENERIC: suspended auth failures use generic copy (web + API).
FC3 SAME: admin soft-delete = 30-day SoftDeletable window.
R1: Suspend revokes sessions + API tokens immediately.
FC4 NONE: no further dark corners.

## Dark corners & pitfalls
- **Pundit default-deny** on every `Admin::*` controller/action; non-admins must 404/redirect without existence leaks of the panel.
- **Suspend vs SoftDeletable:** suspended users are still `kept` (O3A); auth must reject suspended on web session + API token create/use; soft-deleted users already use discarded auth paths — don’t conflate.
- **Revoke credentials on Suspend:** should Suspend revoke active sessions/API tokens immediately? (Recommended yes as impl default / risk R1 if not called out — treat as required behavior under O2A Suspend = cannot sign in.)
- **Admin cannot soft-delete / suspend themselves** (or the last admin) — guardrails in services.
- **Wishlist report triage:** actions target owner and/or wishlist; UI must make the object of Suspend vs soft-delete explicit (user vs list).
- **O4A reopen dismissed→pending** re-enables duplicate-pending unique index behavior — only one pending per reporter/target.
- **Gifter/link (O5A)** only in Hotwire admin detail — never serialize into `/api/v1` even for admin tokens (O1A = web panel only; no admin JSON API required).
- **1-click revert** never mutates old AuditEvents; restore only within SoftDeletable window; unsuspend clears flag + new AuditEvent.
- **Rate limits:** admin mutations should still be sensible; don’t leave admin writes unlimited if easy to declare (impl tuning).
- **O7A:** no Notification rows for triage — tests must assert absence.
- **Flutter:** no Admin screens (O1A); suspended members fail auth like any failed login if FC2 GENERIC.
- **Provisioning (O6A):** document seed/console in plan/docs step; no promote UI to “accidentally” build.

## Domain Model — CONFIRMED (start-task hands-off 2026-11-26)
- **User (admin + suspend):** `role` user|admin; new suspend flag/column. Invariants: Suspend ⇒ cannot authenticate (FC2 GENERIC copy); R1 revoke sessions/api_tokens/device_tokens; still `kept` (O3A — content visible to existing accessors); cannot suspend/soft-delete self or last admin.
- **Report (triage):** pending → dismissed (O2A) or reviewed when enforcement applied; AuditEvents; no Notifications (O7A). Reopen dismissed→pending (FC1 KEEP) respects unique pending index.
- **Admin soft-delete:** SoftDeletable on User and/or Wishlist by admin actor; FC3 SAME 30-day restore; O4A restore compensating action.
- **AuditEvent:** immutable; viewer filters; revert = new compensating action + new event (O4A).
- **GiftRecord admin view:** gifter identity + purchase_link_ref read-only in Hotwire only (O5A); never `/api/v1`.
- **Admin session:** cookie WebAuthentication + `role=admin` + Pundit default-deny (O1A). No Flutter Admin. No promote UI (O6A).
- **Value objects / branded:** none new required beyond existing ReportReason; Suspend state is boolean/timestamp on User (impl chooses `suspended_at` vs boolean — prefer `suspended_at` nullable for auditability).

## Working notes
- Sprint 8 explore discovery complete pending CONFIRM PLAN.
- Explore must not write product code; coding = start-task on new worker.
- Scan plan: no finish-branch / PR / QA / merge steps present.

## Lock checklist — **PASS** (step 1.4)
- Opening triad recorded
- Classification: Feature
- Domain Model populated (User suspend/admin, Report triage, SoftDeletable admin, AuditEvent revert, GiftRecord admin view)
- Final check done (FINAL OK; FC1 KEEP, FC2 GENERIC, FC3 SAME, R1, FC4 NONE)
- Dark corners recorded
- All opens answered / deferred / risk (O1A–O7A + FC1–FC3 + R1)
- Behaviour matrix already exists (`docs/core/BEHAVIOUR_MATRIX.md`) — offer skipped
- `<implementation_plan>` written (TDD; ends at local green suites; no finish-branch / PR / QA / merge)

  <implementation_plan>
    <step id="1" status="complete">Write failing RSpec for User Suspend domain: add nullable `suspended_at` (or equivalent); `User.suspend!(actor:)` sets flag, records AuditEvent `user.suspended`, **revokes sessions + api_tokens + device_tokens** (R1), rejects self-suspend and suspending the last remaining admin; `User.unsuspend!(actor:)` clears flag + AuditEvent `user.unsuspended`. Suspended user remains SoftDeletable `kept` (O3A). Trace `[REQ-ADM-001]`.</step>
    <step id="2" status="complete">Implement minimal Suspend/Unsuspend domain (+ migration) until step 1 green. No controllers yet.</step>
    <step id="3" status="complete">Write failing specs: web session create and API login/token auth reject suspended users with the **same generic** failure as bad credentials (FC2 GENERIC); discarded soft-delete auth paths unchanged. Trace `[REQ-ADM-001]`, `[REQ-AUTH-001]`.</step>
    <step id="4" status="complete">Wire Suspend into authentication paths until step 3 green (no explicit “suspended” copy).</step>
    <step id="5" status="complete">Write failing RSpec for Report triage domain: `dismiss!(actor:)` → `dismissed` + AuditEvent; `review_with_suspend!(actor:, target_user:)` / admin soft-delete account and/or wishlist → `reviewed` + AuditEvents; assert **no** Notification created (O7A); member UserBlock untouched; soft-delete uses SoftDeletable with **30-day** window (FC3 SAME); cannot target self/last admin. Trace `[REQ-ADM-001]`, `[REQ-DISC-001]`, `[REQ-LIFE-001]`.</step>
    <step id="6" status="complete">Implement Report triage + admin soft-delete service methods until step 5 green.</step>
    <step id="7" status="complete">Write failing RSpec for moderation revert helpers (O4A/FC1): unsuspend; restore admin soft-deleted user/wishlist within window; reopen `dismissed`→`pending` (unique pending respected); each creates **new** AuditEvent and never mutates old rows. Trace `[REQ-ADM-001]`.</step>
    <step id="8" status="complete">Implement revert helpers until step 7 green.</step>
    <step id="9" status="complete">Write failing request/system specs for Hotwire Admin gate (O1A/O6A): only `role=admin` cookie session reaches `/admin` (non-admin → not-found or non-revealing redirect); pending Reports index (User + Wishlist); show report with clear user-vs-wishlist action targets; actions dismiss / suspend / soft-delete account / soft-delete wishlist; rate_limit on admin writes. Trace `[REQ-ADM-001]`.</step>
    <step id="10" status="complete">Implement Admin:: namespace (routes, base controller, Pundit AdminPolicy default-deny, reports queue UI) until step 9 green. No promote-admin UI.</step>
    <step id="11" status="complete">Write failing request/system specs for AuditEvent viewer + 1-click revert buttons (O4A): filter/list events; unsuspend / restore / reopen dismissed from viewer; compensating AuditEvents. Trace `[REQ-ADM-001]`.</step>
    <step id="12" status="complete">Implement audit viewer + revert UI until step 11 green.</step>
    <step id="13" status="complete">Write failing system/request specs for O5A: from admin gift/item/audit detail, admin sees gifter `@username` + email + `purchase_link_ref` when present; assert member API JSON still omits those fields (including when caller user has role admin via API — no admin JSON API). Trace `[REQ-ADM-001]`, `[REQ-GIFT-001]`.</step>
    <step id="14" status="complete">Implement Hotwire admin gift/audit detail partials until step 13 green.</step>
    <step id="15" status="complete">Update in-repo docs: API_CONTRACT / SPEC / SCHEMA / DATA_FLOW notes for Suspend, admin soft-delete, triage, revert, admin-only gifter/link web view; document O6A seed/console provisioning; leave ROADMAP Sprint 8 checkboxes for later sync/finish. No ADR unless a boundary is violated (O1A says none). No Flutter Admin screens or mobile changes beyond auth generic failure if shared client copy needs a string tweak for FC2.</step>
    <step id="16" status="complete">Run full `backend` RSpec + RuboCop and `mobile` `flutter analyze` / `flutter test`; fix failures until green. End of `start-task` implementation scope.</step>
  </implementation_plan>

## Handoff status — **PHASE 3 COMPLETE**
- Spec complete pending owner **CONFIRM PLAN**.
- Phase 2 will validate: Feature TDD (failing-test steps 1/3/5/7/9/11/13), architecture OK (Web-only Admin Hotwire; no Flutter Admin; AuditEvent immutable), no wrapping steps in plan.
- **Next after confirm:** owner/coordinator runs **`start-task`** (hands-off) on a **new worker**. This explore agent does **not** write product code.

</task_session>

## QA reviewer record — 2026-11-27 (Sprint 8 Admin/Moderation)
delivery: not posted

What was tested (cloud, headless): User Suspend + FC2 auth; Report triage (dismiss/suspend/soft-delete, O7A no Notification); moderation revert; Hotwire /admin gate + reports + audit revert + gift O5A; O6A no promote UI; S7 report regression; full RSpec 352/0; Flutter analyze + 56 tests.

Results: All cloud matrix rows QA-S8-01–13 **passed**. QA-S8-14 owner to run (real-browser Admin). QA-S8-15 out of scope.

Environment: Ruby 3.4.13, Flutter 3.50.1, Postgres 16, branch cursor/sprint-8-admin-moderation-f6bf. No computerUse; no live SMTP/FCM.

Product bugs: none.
