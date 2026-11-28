<task_session>
  <metadata>
    <task_name>Admin Brand / Style Guide</task_name>
    <type>Feature</type>
    <req_id>REQ-ARCH-001, REQ-ADM-001</req_id>
    <roadmap_item>Backlog — Admin Brand / Style Guide (Web Admin dual preview)</roadmap_item>
    <source>Recreated on this checkout from docs/admin-brand-style-guide-explore.md (explore session was not on this VM). Locks O1A–O3A, O4R, O6A–O9A. Domain model: none.</source>
  </metadata>

  <implementation_plan>
    <step id="1" status="complete">Commit the accepted Backlog bullet (O8A, wording O4R+O9A) in docs/ROADMAP.md. No product code.</step>
    <step id="2" status="complete">Failing test, then a shared DesignTokens file at design/design_tokens.json with a version stamp, read by a Ruby catalog. Today's tokens only (O7A). Do not rewrite mobile/lib/core/theme/design_tokens.dart.</step>
    <step id="3" status="complete">Failing Flutter test, then a new reader that loads design/design_tokens.json and matches palette 01 against the existing DesignTokens fallback. Additive only: no edits to design_tokens.dart, design_tokens_test.dart, or main.dart (Sprint 9 owns main.dart). Do not merge cursor/sprint-9-mobile-wrap-up-5dfd.</step>
    <step id="4" status="complete">Failing request spec, then Admin gate for GET /admin/style_guide: 200 for role=admin cookie session, 404 for members and guests (O1A, O3A). No secret URL.</step>
    <step id="5" status="complete">Failing request spec, then Admin nav link, tokens table, light/dark and es/en toggles, version stamp, and CSS variables driven by the shared file. Admin guide only (not a member theme).</step>
    <step id="6" status="complete">Failing request spec, then web preview: inert sample flows, button states, a11y notes, do/don't. No live mutations.</step>
    <step id="7" status="complete">Failing request spec, then mobile preview: HTML/CSS phone mock from the shared tokens (O4R, O9A). Not Flutter Web and not pixel-identical.</step>
    <step id="8" status="complete">Failing request spec, then print CSS so the guide can be printed or saved as PDF (O3A). Hover may flatten.</step>
    <step id="9" status="complete">Document the shared file and the Admin guide in architecture and the API contract.</step>
    <step id="10" status="complete">Run the Rails and Flutter suites and record that they are green. End of the implementation plan. Do not start QA, finish-branch, or a PR.</step>
  </implementation_plan>

  ## Domain Model

  **none** — Presentational Admin guide + shared tokens + HTML/CSS mobile mock. Inert demos only. Confirmed for hands-off start-task (explore lock).

  <working_notes>
  Sprint 9 branch cursor/sprint-9-mobile-wrap-up-5dfd does not currently change design_tokens.dart. It does change main.dart, pubspec.yaml, routes.rb, locales, ROADMAP, API_CONTRACT, and SYSTEM_ARCHITECTURE. This task stays additive and does not merge that branch.
  Suites 2026-11-27: RSpec 388 examples, 0 failures. RuboCop 213 files, no offenses. flutter analyze clean. flutter test all passed (theme folder includes the shared catalog reader).
  Paused before QA, finish-branch, and any PR.
  Rebase 2026-11-27: onto origin/main 707475e (Sprint 9 PR #16). Conflicts resolved in current_state.md (keep this task) and SYSTEM_ARCHITECTURE.md (keep Sprint 9 surfaces plus the shared tokens bullet). ROADMAP, locales, and routes merged and were checked. Published with lease to cursor/admin-brand-style-guide-ea18 at 34efec0.
  QA pause at step 3.2: smoke QA-01..03 pass. QA-04..07 and QA-09..14 pass. QA-08 failed as a test mistake (expected raw "Do and don't"; the page renders "Do and don&#39;t"). Flutter shared catalog test passed. Full RSpec 435/0 and Flutter suite green on this commit. Temporary spec left at backend/tmp/qa-specs/admin_brand_style_guide_qa_spec.rb until FIX or CONTINUE. No reviewer record yet. No finish-branch and no PR.
  </working_notes>
</task_session>
