# QA Profile — Wish List Community

Project-owned. Not overwritten by agentic:guild sync. Updated only with owner confirmation.

## Section A. Project

| Field | Value |
| :--- | :--- |
| Product kind | Dual: mobile app (Flutter `mobile/`) + Rails API (`backend/`) as needed for API rows; Hotwire web for Secret Link (+ reservation/gift/report) **and Web-only Admin panel** (`/admin`) |
| Framework / language | Flutter / Dart (`mobile/`); Ruby on Rails 8 (`backend/`) + Hotwire/Tailwind for `/s/:share_token` and `/admin` |
| Has user interface | Yes (Flutter screens + Hotwire Secret Link + Hotwire Admin). API rows are headless HTTP/RSpec. |

## Section B. Running it

| Field | Value |
| :--- | :--- |
| Start command (mobile) | `cd mobile && flutter run --dart-define=API_BASE_URL=<https-url>` |
| Start command (API) | `cd backend && bin/rails server` (API/Admin QA rows for this PR use RSpec/factories; Solid Queue job specs run in-process via `perform_now`; email asserted with `have_enqueued_mail` — no live SMTP/FCM) |
| Where QA runs | Cloud agents: **headless only**. Mobile: `flutter test` and temporary `test_qa/`. API + Hotwire Admin/Secret Link: RSpec request specs (no browser agent). Simulator / device / `integration_test/` / Maestro / real WhatsApp OG / real email or push delivery / real-browser Admin walk = **owner to run**. |
| Cloud agent scope | May run headless Flutter widget/unit/QA tests and RSpec. Must not use browser/computerUse agents or simulators. Must not send real email or FCM push. Must not hit live storefronts (WebMock only if OG rows reappear). |
| Owner-only parts | iOS/Android simulator or device; `integration_test/`; Maestro; real-device member UX; real-browser `/admin` triage/revert under load; real WhatsApp/Telegram OG card; live SMTP/FCM delivery |
| Test data (this PR) | Mocked `ApiClient` for Flutter. RSpec factories for users (**including `role: admin`**)/wishlists/items/reservations/`gift_records`/notifications/`reports`. **No seeded staging API** required for cloud QA. |
| Reset | N/A for mocks; Flutter tests use fresh `InMemoryTokenStorage` per case. RSpec uses transactional fixtures/factories. |
| Accounts / roles | **guest**; **authenticated member** (owner / friend / sharee); **admin** (Hotwire cookie `role=admin` via factories). No Flutter Admin. Never store passwords in this profile. |
| Required env var **names** | `API_BASE_URL` (optional in Flutter debug; required `https://` in release). Backend test DB per `backend/` conventions when RSpec rows run. |

## Section C. Tests

| Field | Value |
| :--- | :--- |
| QA test command (mobile) | `cd mobile && flutter test test_qa` (temporary QA folder; not the main suite) |
| QA test command (API) | `cd backend && bundle exec rspec` (when matrix includes API / Hotwire Admin / Secret Link / domain rows) |
| Project suite (regression) | `cd mobile && flutter test` and `flutter analyze`; `cd backend && bundle exec rspec` |
| Screenshots | `tmp/qa-screenshots/` — **never committed** |
| First surfaces to cover | **Sprint 8 focus:** Suspend + FC2 auth; Report triage (dismiss/suspend/soft-delete; O7A no Notification); moderation revert (unsuspend/restore/reopen); Hotwire `/admin` gate + reports + audit revert + gift O5A detail; no promote UI (O6A). **Regression smoke:** Login; S7 Wishlist report enqueue; S6 gifts Path 1/2 smoke; full RSpec + Flutter suite. |
| Locales | `es` (default), `en` (second-locale rule) for Flutter member strings. Admin Hotwire labels English this sprint (no Admin Flutter). |

## Section D. Limits

| Field | Value |
| :--- | :--- |
| Never touch | Production data; live user accounts; production API without mocks; live storefront HTML outside WebMock |
| Forbidden actions | Send real email or push; payments/charges; delete production records; launch browser or computerUse agents; follow SSRF-like URLs to private/link-local/metadata IPs in live checks; Flutter Admin screens or `/api/v1` admin JSON endpoints; expect triage Notifications (O7A); hide content on Suspend alone (O3A) |

## Notes

- Temporary QA tests live under `mobile/test_qa/` (or equivalent path named in the matrix) and are removed after the pass unless the owner asks to keep them.
- Reviewer records are staged in the active session file under `## QA reviewer record` and are immutable once written (delivery marker only may change).
- **Sprint 8:** Web-only Admin Hotwire; Suspend does not hide; soft-delete uses SoftDeletable 30-day window; revert = compensating AuditEvent only; gifter/email/`purchase_link_ref` Hotwire Admin-only; ops provision admins via seed/console (O6A).
- **Sprint 7 (regression):** Enqueue-only Wishlist reports; mutation `rate_limit` ~10–20 / 3 minutes.
- **Sprint 6 (regression):** FCM push send remains no-op; `purchase_link_ref` never in member API JSON.
- **Client-side image compression:** still deferred (O6A) to Sprint 9 — out of Sprint 8 QA scope.
