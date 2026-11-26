# QA Profile — Wish List Community

Project-owned. Not overwritten by agentic:guild sync. Updated only with owner confirmation.

## Section A. Project

| Field | Value |
| :--- | :--- |
| Product kind | Dual: mobile app (Flutter `mobile/`) + Rails API (`backend/`) as needed for API rows; minimal Hotwire web for Secret Link (+ reservation actions) |
| Framework / language | Flutter / Dart (`mobile/`); Ruby on Rails 8 (`backend/`) + Hotwire/Tailwind for `/s/:share_token` |
| Has user interface | Yes (Flutter screens + Hotwire Secret Link). API rows are headless HTTP/RSpec. |

## Section B. Running it

| Field | Value |
| :--- | :--- |
| Start command (mobile) | `cd mobile && flutter run --dart-define=API_BASE_URL=<https-url>` |
| Start command (API) | `cd backend && bin/rails server` (API QA rows for this PR use RSpec/factories; Solid Queue job specs run in-process via `perform_now`; email asserted with `have_enqueued_mail` — no live SMTP/FCM) |
| Where QA runs | Cloud agents: **headless only**. Mobile: `flutter test` and temporary `test_qa/`. API: RSpec. Hotwire Secret Link + reservations: RSpec request specs (no browser agent). Simulator / device / `integration_test/` / Maestro / real WhatsApp OG / real email or push delivery = **owner to run**. |
| Cloud agent scope | May run headless Flutter widget/unit/QA tests and RSpec. Must not use browser/computerUse agents or simulators. Must not send real email or FCM push. Must not hit live storefronts (WebMock only if OG rows reappear). |
| Owner-only parts | iOS/Android simulator or device; `integration_test/`; Maestro; real-device reserve/extend/cancel UX (Flutter + Hotwire); real WhatsApp/Telegram OG card; live SMTP/FCM delivery |
| Test data (this PR) | Mocked `ApiClient` transport / in-memory fakes for Flutter. RSpec factories for users/wishlists/items/**reservations**/notifications. **No seeded staging API** required for cloud QA. |
| Reset | N/A for mocks; Flutter tests use fresh `InMemoryTokenStorage` per case. RSpec uses transactional fixtures/factories. |
| Accounts / roles | **guest** (unauthenticated Secret Link); **authenticated member** (owner / friend / sharee via factories or mock profile). Owner must not see reservation spoilers. No admin on mobile. Never store passwords in this profile. |
| Required env var **names** | `API_BASE_URL` (optional in Flutter debug; required `https://` in release). Backend test DB per `backend/` conventions when RSpec API rows run. |

## Section C. Tests

| Field | Value |
| :--- | :--- |
| QA test command (mobile) | `cd mobile && flutter test test_qa` (temporary QA folder; not the main suite) |
| QA test command (API) | `cd backend && bundle exec rspec` (when matrix includes API / Hotwire / reservation / notification / job rows) |
| Project suite (regression) | `cd mobile && flutter test` and `flutter analyze`; `cd backend && bundle exec rspec` |
| Screenshots | `tmp/qa-screenshots/` — **never committed** |
| First surfaces to cover | **Sprint 5 focus:** `POST/PATCH/DELETE` reservations + 409 race; `availability` on non-owner items; `GET /my_reservations`; notification prefs/inbox + dispatcher; `ReservationGraceSweepJob`; Hotwire `/s/:share_token` reserve/extend/cancel (O4B) with guest still login-gated; Flutter reserve on non-owner detail + `MyReservationsScreen`. **Regression smoke:** `LoginScreen`, `SignUpScreen`, `MyWishlistsScreen`, `SharedWishlistsScreen`, item list/form (S4). |
| Locales | `es` (default), `en` (second-locale rule) for Flutter reservation strings |

## Section D. Limits

| Field | Value |
| :--- | :--- |
| Never touch | Production data; live user accounts; production API without mocks; live storefront HTML outside WebMock |
| Forbidden actions | Send real email or push; payments/charges; delete production records; launch browser or computerUse agents; follow SSRF-like URLs to private/link-local/metadata IPs in live checks; mark gift/`purchased_secret` paths as in-scope (Sprint 6) |

## Notes

- Temporary QA tests live under `mobile/test_qa/` (or equivalent path named in the matrix) and are removed after the pass unless the owner asks to keep them.
- Reviewer records are staged in the active session file under `## QA reviewer record` and are immutable once written (delivery marker only may change).
- **Sprint 5:** FCM push send is intentionally no-op (O1A); assert preference + no-op boundary, not live delivery.
- **Sprint 5:** Gift dual-path / `purchased_secret` / Received Gifts = Sprint 6 — out of this QA scope.
- **Secret Link (O4B):** Logged-in sharees get the same reservation actions as Flutter; guests remain invitation/view + login/`return_to` to reserve. Owner browsing own link must not see reservation spoilers.
- **Client-side image compression:** still deferred (O6A) to Sprint 9 — out of Sprint 5 QA scope.
