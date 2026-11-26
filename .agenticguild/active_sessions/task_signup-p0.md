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
    <step id="3" status="complete">Write failing Flutter AuthRepository.signUp unit test: POST /api/v1/signup with email/username/password/locale/time_zone/terms_accepted, stores token, returns UserProfile [REQ-AUTH-001] [REQ-AUTH-002].</step>
    <step id="4" status="complete">Implement AuthRepository.signUp — make Step 3 GREEN.</step>
    <step id="5" status="complete">Write failing widget/repo tests for SignUpScreen + LoginScreen navigation + bilingual AppStrings signup keys [REQ-AUTH-002] [REQ-USER-002].</step>
    <step id="6" status="complete">Implement SignUpScreen, wire LoginScreen signup link, extend AppStrings (es/en) — make Step 5 GREEN.</step>
    <step id="7" status="complete">Update docs/core/API_CONTRACT.md with POST /api/v1/signup and correct docs/ROADMAP.md signup Done wording to match shipped surface (API+Flutter).</step>
  </implementation_plan>

  <working_notes>
    Endpoint: POST /api/v1/signup (matches SPEC rate_limit on /signup).
    Response shape mirrors POST /api/v1/session (201 + token + public user).
    terms_accepted boolean → sets terms_accepted_at = Time.current when true; absent/false → 422.
    Out of scope: wishlists, design retokenize, notifications.
    Owner prefs: start_task_mode hands-off; finish_branch_mode stepped.
  </working_notes>
</task_session>


## Code review pass 1 (2026-11-26)

### MUST FIX
None

### STRONGLY RECOMMENDED
1. `SignUpScreen` hardcodes `timeZone: 'UTC'` (`mobile/lib/features/auth/sign_up_screen.dart`) — new accounts ignore device/local TZ (`REQ-USER-003`). Fix: pass a real timezone (device/local) or collect it on the form.
2. No password confirmation field on `SignUpScreen` — typos are only caught if the API rejects weak/blank passwords; confirmation never mismatches because the repo mirrors `password`. Fix: add confirm field and client-side match check.

### NICE TO IMPROVE
3. Submit button stays enabled when terms checkbox is unchecked (fails via ArgumentError → friendly error). Prefer disable until checked.
4. Signup rate_limit request example only asserts source/`respond_to?(:rate_limit)` because test `cache_store` is `:null_store` (same limitation as other auth endpoints).
5. `AuthRepository` file header traceability comment still omits `REQ-AUTH-002`.

### Sync-docs candidate list (await owner accept/reject)
- `docs/core/TESTING_STRATEGY_MATRIX.md` — add SignUpScreen / signup repo coverage
- `docs/ai/qa_profile.md` — add SignUpScreen to first surfaces
- Already updated in-branch (chore Done): `docs/core/API_CONTRACT.md`, `docs/ROADMAP.md`, `docs/core/SYSTEM_ARCHITECTURE.md`

## QA reviewer record (2026-11-26) — not posted

Environment: local Ruby 3.4.13 + Flutter stable; Postgres test DB; mocked ApiClient for mobile.

| ID | Surface | Result |
| :--- | :--- | :--- |
| Q1 | `bundle exec rspec` (78 examples incl. signup) | passed |
| Q2 | `flutter test` (42 examples incl. signup flow) | passed |
| Q3 | `flutter analyze` | passed |
| Q4 | Login → SignUp → POST /api/v1/signup widget | passed |
| Q5 | AuthRepository.signUp terms gate | passed |
| O1 | Device/simulator visual signup | owner to run |

Status: not posted
