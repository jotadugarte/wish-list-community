# QA Profile — Wish List Community

Project-owned. Not overwritten by agentic:guild sync. Updated only with owner confirmation.

## Section A. Project

| Field | Value |
| :--- | :--- |
| Product kind | Dual: mobile app (Flutter `mobile/`) + Rails API (`backend/`) as needed for API rows |
| Framework / language | Flutter / Dart (`mobile/`); Ruby on Rails 8 (`backend/`) |
| Has user interface | Yes (Flutter screens). API rows are headless HTTP/RSpec. |

## Section B. Running it

| Field | Value |
| :--- | :--- |
| Start command (mobile) | `cd mobile && flutter run --dart-define=API_BASE_URL=<https-url>` |
| Start command (API) | `cd backend && bin/rails server` (API rows for this PR use mocks / RSpec, not a live server) |
| Where QA runs | Cloud agents: **headless only**. Mobile: `flutter test` and temporary `test_qa/`. API: RSpec. Simulator / device / `integration_test` / Maestro = **owner to run**. |
| Cloud agent scope | May run headless Flutter widget/unit tests and RSpec. Must not use browser/computerUse agents or simulators. |
| Owner-only parts | iOS/Android simulator or device, `integration_test/`, Maestro, any real-device checks |
| Test data (this PR) | Mocked `ApiClient` transport / in-memory fakes. **No seeded staging API** for this PR. |
| Reset | N/A for mocks; Flutter tests use fresh `InMemoryTokenStorage` per case. RSpec uses transactional fixtures/factories when API rows run. |
| Accounts / roles | **guest** (unauthenticated) and **authenticated member** (mock profile). No admin on mobile. Never store passwords in this profile. |
| Required env var **names** | `API_BASE_URL` (optional in Flutter debug; required `https://` in release). Backend test env per `backend/` conventions when RSpec API rows run. |

## Section C. Tests

| Field | Value |
| :--- | :--- |
| QA test command (mobile) | `cd mobile && flutter test test_qa` (temporary QA folder; not the main suite) |
| QA test command (API) | `cd backend && bundle exec rspec` (only when matrix includes API rows) |
| Project suite (regression) | `cd mobile && flutter test` and `flutter analyze` |
| Screenshots | `tmp/qa-screenshots/` — **never committed** |
| First surfaces to cover | `LoginScreen`, `PasswordResetScreen`, `AccountRestoreScreen`, `FriendsListScreen`, `UserSearchScreen`, `ProfileSettingsScreen` |
| Locales | `es` (default), `en` (second-locale rule) |

## Section D. Limits

| Field | Value |
| :--- | :--- |
| Never touch | Production data; live user accounts; production API without mocks |
| Forbidden actions | Send real email or push; payments/charges; delete production records; launch browser or computerUse agents |

## Notes

- Temporary QA tests live under `mobile/test_qa/` (or equivalent path named in the matrix) and are removed after the pass unless the owner asks to keep them.
- Reviewer records are staged in the active session file under `## QA reviewer record` and are immutable once written (delivery marker only may change).
