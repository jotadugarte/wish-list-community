<task_session>
  <metadata>
    <task_name>Signup P0 API and Flutter screen</task_name>
    <type>Chore</type>
    <req_id>REQ-AUTH-001, REQ-AUTH-002, REQ-AUTH-003, REQ-USER-001, REQ-USER-002, REQ-USER-003</req_id>
    <roadmap_item>Sprint 1 Authentication (sign up with terms_accepted_at) — P0 before Sprint 3 (D1a Locked)</roadmap_item>
  </metadata>

  <implementation_plan>
    <step id="1" status="complete">Write failing request specs for POST /api/v1/signup: creates user with terms_accepted_at when terms_accepted=true, rejects missing terms (422), rejects invalid/duplicate identity (422), issues bearer token+user payload like session create, and declares rate_limit [REQ-AUTH-001] [REQ-AUTH-002] [REQ-AUTH-003] [REQ-USER-001] [REQ-USER-002] [REQ-USER-003].</step>
    <step id="2" status="complete">Implement Api::V1::SignupsController + route resource :signup (create only) with rate_limit, terms gating, User creation via EmailAddress/Username VOs, ApiToken.issue_for!, and localized 422 errors — make Step 1 specs GREEN.</step>
    <step id="3" status="pending">Write failing Flutter AuthRepository.signUp unit test: POST /api/v1/signup with email/username/password/locale/time_zone/terms_accepted, stores token, returns UserProfile [REQ-AUTH-001] [REQ-AUTH-002].</step>
    <step id="4" status="pending">Implement AuthRepository.signUp — make Step 3 GREEN.</step>
    <step id="5" status="pending">Write failing widget/repo tests for SignUpScreen + LoginScreen navigation + bilingual AppStrings signup keys [REQ-AUTH-002] [REQ-USER-002].</step>
    <step id="6" status="pending">Implement SignUpScreen, wire LoginScreen signup link, extend AppStrings (es/en) — make Step 5 GREEN.</step>
    <step id="7" status="pending">Update docs/core/API_CONTRACT.md with POST /api/v1/signup and correct docs/ROADMAP.md signup Done wording to match shipped surface (API+Flutter).</step>
  </implementation_plan>

  <working_notes>
    Endpoint: POST /api/v1/signup (matches SPEC rate_limit on /signup).
    Response shape mirrors POST /api/v1/session (201 + token + public user).
    terms_accepted boolean → sets terms_accepted_at = Time.current when true; absent/false → 422.
    Out of scope: wishlists, design retokenize, notifications.
    Owner prefs: start_task_mode hands-off; finish_branch_mode stepped.
  </working_notes>
</task_session>
