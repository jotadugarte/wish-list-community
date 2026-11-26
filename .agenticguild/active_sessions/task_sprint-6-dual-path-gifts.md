<task_session>
  <metadata>
    <task_name>Sprint 6 Dual-Path Gift Fulfillment + Anonymous Thank-You</task_name>
    <type>Feature</type>
    <req_id>REQ-GIFT-001, REQ-GIFT-002, REQ-GIFT-003, REQ-GIFT-004, REQ-ITEM-004, REQ-ADM-001, REQ-RES-006, REQ-NOTIF-001</req_id>
    <roadmap_item>MVP Sprint 6 — Dual-Path Gift Fulfillment + Anonymous Thank-You Note</roadmap_item>
    <base>origin/main @ 27a42cf (Merge PR #12 — Sprint 5 Secret Reservations)</base>
    <explore_doc>/cursor/stores/bc-32a5179f-cc50-4940-94d7-70abc32641c4/docs/sprint-6-roadmap-explore.md</explore_doc>
  </metadata>

  <classification>Feature</classification>

  <opening_triad>
    <what_we_know>
      Sprint 5 is on origin/main (PR #12). Reservation exists with statuses active / expired_grace / auto_released / canceled only.
      Partial unique index holds one active|expired_grace per item. Viewer-relative availability (O3A) ships for non-owners; omitted for owner.
      Mark purchased during grace was explicitly deferred to Sprint 6 (O2A). Notification foundation + dispatcher exist (O1A/O8A); push still no-op until S9.
      Hotwire Secret Link already has reserve/extend/cancel parity (O4B). SPEC §4.5 names Reservation &amp; GiftRecord together; REQ-GIFT-001..004 + REQ-ITEM-004 define dual-path, unified unavailable, owner 1-step receive, anonymous thank-you, Received Gifts section.
      No GiftRecord model/table yet. Architecture already lists gift-fulfillment Service Objects as the pattern.
    </what_we_know>
    <what_we_dont_know>
      (none material — Final check accepted; plan written)
    </what_we_dont_know>
    <what_we_need_to_define>
      Spec locked. Owner/coordinator launches start-task on a new worker when ready. This explore session does not code.
    </what_we_need_to_define>
  </opening_triad>

  <carry_forward_locks>
    <lock id="O1B">Gift lifecycle lives on new GiftRecord; Reservation remains the hold (terminal completed_by_gift when Path 1 starts). Locked owner 2026-11-26.</lock>
    <lock id="O2A">GiftRecord owns post-purchase block: partial unique on open gifts (purchased_secret|delivered_pending_confirmation); availability = hold OR open gift; received_confirmed → Received Gifts. Reservation unique index stays S5-only. Locked owner 2026-11-26.</lock>
    <lock id="O3C">Full web + Flutter parity for Sprint 6 gift actions (Path 1, Path 2, thank-you, Received Gifts) — not API/Flutter-only. Locked owner 2026-11-26.</lock>
    <lock id="O4A">Optional purchase_link_ref on GiftRecord at mark purchased (ItemLink or pasted URL; blank OK); admin-only / never owner-friend serializers; AuditEvent on capture. Locked owner 2026-11-26.</lock>
    <lock id="O5A">Optional thank-you field on the same confirm-receipt step (Path 1 and Path 2); blank = no thank-you notification; note → private to gifter only; no add-later in S6. Locked owner 2026-11-26.</lock>
    <lock id="O6A">Mark purchased allowed from active and expired_grace; success → GiftRecord purchased_secret + Reservation completed_by_gift (sweep ignores); grace UI Extend|Cancel|Mark purchased; no mark on auto_released hold. Locked owner 2026-11-26.</lock>
    <lock id="O7A">Minimal S6 gift notifications via existing dispatcher: gift.delivered_pending_confirmation → owner (anonymous); gift.received_confirmed_to_gifter → gifter on confirm (Path 1/2); gift.thank_you → gifter if O5A note non-empty; defaults-on; push no-op. Locked owner 2026-11-26.</lock>
    <lock id="O8D">Open gifts voided and stop blocking; restore never reopens. Owner soft-deletes item OR wishlist → void + notify gifter. Owner block/unfriend → void, no notify; clear pending delivery-confirm. Gifter block/unfriend while open → warn/confirm UI first (web+app); on confirm void (clear owner pending prompt if any). received_confirmed not voided (soft-delete visibility only). Owner account soft-delete → notify gifters like item/wishlist delete. Locked owner 2026-11-26.</lock>
    <lock id="FC1">Path 2 on free item: received_confirmed with no gifter; no thank-you field. Accepted Final check 2026-11-26.</lock>
    <lock id="FC2">Keep O3A availability enum (available|reserved_by_me|unavailable); gifter after purchase still reserved_by_me. Accepted Final check 2026-11-26.</lock>
    <lock id="client-parity-durable">Durable owner preference: every feature must offer the same options on web and apps (parity by default). Recorded 2026-11-26 with O3C.</lock>
    <lock id="O2A-S5">Mark purchased / gift dual-path is Sprint 6 (not S5).</lock>
    <lock id="O3A-S5">Non-owners get availability available|reserved_by_me|unavailable; omitted for owner. S6 may map secretly purchased onto unavailable.</lock>
    <lock id="O4B-S5">Hotwire Secret Link has reservation action parity with Flutter; gift-action parity is a new open for S6.</lock>
    <lock id="O1A-O8A-S5">Notification + preferences + dispatcher foundation exists; extend with S6 event keys, push still no-op.</lock>
    <lock id="D6a">Superseded for client UX by O3C + client-parity-durable: gift (and future) features ship same options on web and apps. API remains server authority.</lock>
    <lock id="zero-spoilers">Owner never sees active/grace/purchased_secret; never mutate items.updated_at on reservation/gift transitions.</lock>
  </carry_forward_locks>

  <decisions>
    <decision id="O1" status="Locked" chosen="B" locked_at="2026-11-26">
      <summary>New GiftRecord table for gift lifecycle; Reservation remains the secret hold and moves to completed_by_gift when Path 1 (mark purchased) starts.</summary>
    </decision>
    <decision id="O2" status="Locked" chosen="A" locked_at="2026-11-26">
      <summary>GiftRecord owns post-purchase uniqueness and Unavailable (open: purchased_secret|delivered_pending_confirmation). Availability = active/grace hold OR open GiftRecord. received_confirmed → Received Gifts. Reservation unique index stays S5-only; Path 1 completes hold so grace stops.</summary>
    </decision>
    <decision id="O3" status="Locked" chosen="C" locked_at="2026-11-26">
      <summary>Full web + Flutter parity for gift actions: Flutter and Hotwire (Secret Link sharees + owner wishlist surfaces) get the same Path 1 / Path 2 / thank-you / Received Gifts options. Durable rule: every feature must have the same options on web and apps.</summary>
    </decision>
    <decision id="O4" status="Locked" chosen="A" locked_at="2026-11-26">
      <summary>Optional purchase_link_ref on GiftRecord when marking purchased_secret (pick ItemLink or paste URL; blank allowed). Admin-only field; AuditEvent on capture; S6 persists, Sprint 8 admin UI reads.</summary>
    </decision>
    <decision id="O5" status="Locked" chosen="A" locked_at="2026-11-26">
      <summary>Optional thank-you on confirm-receipt step (Path 1 + Path 2); blank skips notification; non-empty note delivered privately to gifter; no later edit flow in S6.</summary>
    </decision>
    <decision id="O6" status="Locked" chosen="A" locked_at="2026-11-26">
      <summary>Mark purchased from active or expired_grace; creates GiftRecord purchased_secret and completes Reservation (completed_by_gift); grace UI Extend|Cancel|Mark purchased; auto_released holds cannot be marked purchased.</summary>
    </decision>
    <decision id="O7" status="Locked" chosen="A" locked_at="2026-11-26">
      <summary>Minimal gift event keys via NotificationDispatcher: delivered_pending_confirmation → owner anonymous; received_confirmed_to_gifter → gifter; thank_you → gifter when note present; defaults-on; push no-op.</summary>
    </decision>
    <decision id="O8" status="Locked" chosen="D" locked_at="2026-11-26">
      <summary>Custom O8D: void open gifts so they stop blocking; restore never reopens. Owner item/wishlist soft-delete → void + notify gifter. Owner block/unfriend → void, no notify + clear pending delivery confirm. Gifter block/unfriend while open → warn/confirm (web+app) then void. received_confirmed not voided. Owner account soft-delete notifies gifters like delete.</summary>
    </decision>
  </decisions>

  <domain_model>
    <note>SPEC LOCKED 2026-11-26. Plan confirmed. start-task Phase 3.0: Domain Model confirmed hands-off — Reservation (+ ReservationStatus with completed_by_gift, EstimatedDate); GiftRecord (+ GiftStatus including voided, ThankYouNote, PurchaseLinkRef). Proceeding to Step 1.</note>
    <entity name="Reservation" responsibility="Secret hold on one Item by one User (S5). Terminal completed_by_gift when Path 1 starts (O1B).">
      <invariants>
        Partial unique index for active|expired_grace; zero spoilers; no items.updated_at mutation; owner cannot reserve own item.
      </invariants>
      <value_objects>ReservationStatus (active, expired_grace, auto_released, canceled, completed_by_gift), EstimatedDate</value_objects>
    </entity>
    <entity name="GiftRecord" responsibility="Dual-path fulfillment + optional anonymous thank-you + purchase link for admin (O1B).">
      <invariants>
        Owner never sees purchased_secret identity; third party cannot override; Path 2 owner receive closes hold and notifies reserver; thank-you reveals nothing about gifter to owner.
        At most one open GiftRecord per item (purchased_secret|delivered_pending_confirmation); availability = hold OR open gift (O2A); received_confirmed → Received Gifts.
        O8D: voided open gifts never block; restore never reopens; owner delete (item/wishlist/account) voids + notifies gifter; owner block/unfriend voids silently; gifter block/unfriend warns first.
      </invariants>
      <value_objects>GiftStatus (purchased_secret, delivered_pending_confirmation, received_confirmed); ThankYouNote; PurchaseLinkRef (admin-only)</value_objects>
    </entity>
  </domain_model>

  <parked_open_for_later>
    (none material — see Final check / dark corners for implementation risks)
  </parked_open_for_later>

  ## Dark corners &amp; pitfalls
  - **Path 2 with no prior reservation:** Owner marks received on an available item — create GiftRecord received_confirmed directly (no gifter); no thank-you recipient. Implementation must allow Path 2 without an open hold/gift.
  - **Path 2 while hold active:** Close hold (canceled or completed_by_gift?) + notify reserver (O7A); if they had purchased_secret already, prefer void/complete gift into received_confirmed without double rows.
  - **Partial unique + races:** Mark purchased vs another reserve; mark delivered vs owner soft-delete; confirm vs void — all must be transactional with clear 409/422.
  - **Availability for gifter after purchased_secret:** reserved_by_me vs a dedicated “my purchase” label — product copy only; same three availability values preferred unless Final check says otherwise (risk: keep O3A enum).
  - **Hotwire + Flutter parity (O3C):** Owner Path 2 + Received Gifts + My Reservations gift actions + warn-on-block UI on both clients — largest S6 surface; scope risk if DesignTokens/HTML lag (pref: proceed with defaults).
  - **Admin purchase_link_ref:** Stored in S6, no admin UI until S8 — document as persist-only; serializers must never leak.
  - **Thank-you with Path 2 and no gifter:** Skip thank-you field when there is no gifter identity to deliver to.
  - **Notification prefs:** New event_keys defaults-on; users with empty preference JSON still get defaults (S5 pattern).
  - **Delivered prompt anonymity:** Payload/title/body must not include gifter username or reservation id that owner-facing clients could misuse — use opaque gift/item ids carefully on owner surfaces.
  - **Wishlist soft-delete cascade:** Must void open gifts per item in one transaction with soft-delete hooks (bounded registry).
  

  <working_notes>
    Process: one decision card per pause; plain who-sees-what before options; recommendation shown; never batch O*.
    No product code. No start-task until explicit owner handoff after plan lock.
    Local main may lag origin/main; explore anchored to origin/main @ 27a42cf.
    2026-11-26: Owner locked O1B. Presenting O2 only.
    2026-11-26: Owner locked O2A. Presenting O3 only.
    2026-11-26: Owner locked O3C + durable preference (same options on web and apps for every feature). Presenting O4 only.
    2026-11-26: Owner locked O4A. Presenting O5 only.
    2026-11-26: Owner locked O5A. Presenting O6 only.
    2026-11-26: Owner locked O6A. Presenting O7 only.
    2026-11-26: Owner locked O7A. Presenting O8 only (last open card).
    2026-11-26: Owner proposed O8 nuance (NOT locked): (1) owner soft-delete item → void open gift + notify gifter; (2) owner block/unfriend → void open gift, no notify; (3) gifter block/unfriend while open → warn/confirm UI first (web+app). Awaiting edge-case review + O8D adopt A/B.
    2026-11-26: Owner locked O8D (wishlist=item+notify; restore never reopens; owner account delete notifies gifters). Entered Final check (1.3).
    2026-11-26: FINAL OK — FC1+FC2 accepted. Step 1.4 lock checklist + implementation_plan written.
    2026-11-26: Owner CONFIRM PLAN (CONTINUE). Plan validated (Feature TDD, architecture OK, no wrapping steps). Discovery complete — handoff to start-task required. Explore will not code.
  </working_notes>

  <phase2_validation>
    <classification>Feature</classification>
    <verification>tdd</verification>
    <step1_failing_test>pass</step1_failing_test>
    <test_first_pairs>pass (failing then implement through step 18; docs+full green 19–20)</test_first_pairs>
    <architecture_anchors>pass — GiftService, Pundit, Hotwire importmap, Flutter /api/v1, no items.updated_at, zero spoilers</architecture_anchors>
    <forbidden_wrapping_steps>pass — none</forbidden_wrapping_steps>
    <plan_confirmed_at>2026-11-26</plan_confirmed_at>
    <handoff>start-task on new worker; explore archive-ready</handoff>
  </phase2_validation>


  <lock_checklist>
    <item status="pass">Opening triad recorded</item>
    <item status="pass">Classification stamped: Feature</item>
    <item status="pass">Domain Model populated (Reservation + GiftRecord)</item>
    <item status="pass">Final check done (FINAL OK)</item>
    <item status="pass">Dark corners recorded</item>
    <item status="pass">Every open answered/deferred/risk (O1–O8 locked; FC1/FC2 accepted; remaining dark corners = implementation risks)</item>
    <item status="skip">Behaviour matrix offer — docs/core/BEHAVIOUR_MATRIX.md already exists</item>
  </lock_checklist>


  <implementation_plan>
    <step id="1" status="complete">Write failing RSpec for GiftStatus VO + GiftRecord model: allowed statuses purchased_secret|delivered_pending_confirmation|received_confirmed|voided; belongs_to item + optional gifter user; optional thank_you_note; optional purchase_link_ref (admin-only field); never touch items.updated_at on gift writes. Trace [REQ-GIFT-001], [REQ-GIFT-002], [REQ-RES-002], [REQ-ADM-001].</step>
    <step id="2" status="complete">Implement migration gift_records + partial unique index on open statuses (purchased_secret|delivered_pending_confirmation) per item (O2A) + GiftStatus/GiftRecord minimally until step 1 green. Extend ReservationStatus with completed_by_gift (O1B).</step>
    <step id="3" status="complete">Write failing RSpec for GiftService#mark_purchased!: only active|expired_grace reserver (O6A); creates GiftRecord purchased_secret; reservation → completed_by_gift; optional purchase_link_ref (O4A); uniqueness/409 if open gift or other hold; AuditEvent; no items.updated_at. Trace [REQ-GIFT-001], [REQ-GIFT-002], [REQ-RES-006].</step>
    <step id="4" status="complete">Implement GiftService#mark_purchased! (+ Pundit gift/reservation policy updates) until step 3 green.</step>
    <step id="5" status="complete">Write failing RSpec for GiftService#mark_delivered!: gifter only from purchased_secret → delivered_pending_confirmation; NotificationDispatcher gift.delivered_pending_confirmation to owner with anonymous copy (O7A); no gifter identity in owner payload/title. Trace [REQ-GIFT-001], [REQ-NOTIF-001].</step>
    <step id="6" status="complete">Implement mark_delivered! until step 5 green.</step>
    <step id="7" status="complete">Write failing RSpec for GiftService#confirm_received! (Path 1) and #owner_mark_received! (Path 2): optional thank_you on same step (O5A); blank = no gift.thank_you; note → private thank_you to gifter; Path 2 closes active/grace hold and/or open gift → received_confirmed + gift.received_confirmed_to_gifter (O7A); FC1: free item with no gifter → received_confirmed, no thank-you field. Trace [REQ-GIFT-001], [REQ-GIFT-003], [REQ-GIFT-004], [REQ-ITEM-004].</step>
    <step id="8" status="complete">Implement confirm_received! / owner_mark_received! until step 7 green.</step>
    <step id="9" status="complete">Write failing Item availability specs: open GiftRecord → unavailable for third parties; gifter → reserved_by_me (FC2); owner omits availability; received_confirmed excluded from open pool / Received Gifts helpers. Trace [REQ-GIFT-002], [REQ-ITEM-004], [REQ-RES-002].</step>
    <step id="10" status="complete">Implement availability + Received Gifts query helpers until step 9 green.</step>
    <step id="11" status="pending">Write failing specs for O8D cascades: owner item/wishlist soft-delete voids open gifts + notifies gifter; owner block/unfriend voids open gifts without notify + clears pending delivery confirm; gifter-initiated block/unfriend requires confirm flag/param (API) mirroring warn UI; restore never reopens voided; owner account soft-delete notifies gifters; received_confirmed not voided. Trace [REQ-LIFE-001], [REQ-BLOCK-002], [REQ-GIFT-002].</step>
    <step id="12" status="pending">Implement SoftDeletable/UserBlock/friendship hooks for GiftRecord until step 11 green (Zeitwerk-safe constant refs; bounded registries).</step>
    <step id="13" status="pending">Write failing API request specs (auth + Pundit): mark purchased/delivered on reservation or gift resources; owner confirm + Path 2 on item; my gifts/reservations surfaces updated; purchase_link_ref never in owner/friend JSON; thank_you only to gifter inbox via notifications. Trace [REQ-GIFT-001..004], [REQ-ARCH-003].</step>
    <step id="14" status="pending">Implement API routes/controllers/serializers until step 13 green (thin controllers; GiftService owns transactions).</step>
    <step id="15" status="pending">Write failing Hotwire/system specs for O3C parity: Secret Link sharee Path 1 (purchased/delivered); owner wishlist Path 2 + thank-you + Received Gifts; warn/confirm before gifter block/unfriend when open gift exists; bilingual copy. Trace [REQ-GIFT-001], [REQ-GIFT-003], [REQ-GIFT-004], [REQ-ITEM-004].</step>
    <step id="16" status="pending">Implement Hotwire controllers/views/Stimulus until step 15 green (importmap only; no SPA frameworks).</step>
    <step id="17" status="pending">Write failing Flutter tests: mark purchased/delivered from My Reservations/item; owner Path 2 + optional thank-you; Received Gifts section; warn before block/unfriend with open gift; AppStrings es/en; DesignTokens defaults. Trace matching REQ-GIFT-* / REQ-ITEM-004.</step>
    <step id="18" status="pending">Implement Flutter repositories/screens/navigation until step 17 green (full parity with web per O3C + durable client-parity preference).</step>
    <step id="19" status="pending">Update living docs as feature work: docs/core/API_CONTRACT.md gift endpoints; ROADMAP Sprint 6 checkboxes only when verified on this branch; ADR only if an architecture law would otherwise be violated. This plan ends at local green suites only.</step>
    <step id="20" status="pending">Run full backend RSpec + flutter analyze/flutter test; fix until green. End of start-task implementation scope.</step>
  </implementation_plan>
</task_session>
