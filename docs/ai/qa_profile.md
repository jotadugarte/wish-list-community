# QA Profile — Wish List Community

Project-owned. Not overwritten by agentic:guild sync. Updated only with owner confirmation.

## Section A. Project

| Field | Value |
| :--- | :--- |
| Product kind | Dual: mobile app (Flutter `mobile/`) + Rails API (`backend/`) as needed for API rows; minimal Hotwire web for Secret Link |
| Framework / language | Flutter / Dart (`mobile/`); Ruby on Rails 8 (`backend/`) + Hotwire/Tailwind for `/s/:share_token` |
| Has user interface | Yes (Flutter screens + Hotwire Secret Link). API rows are headless HTTP/RSpec. |

## Section B. Running it

| Field | Value |
| :--- | :--- |
| Start command (mobile) | `cd mobile && flutter run --dart-define=API_BASE_URL=<https-url>` |
| Start command (API) | `cd backend && bin/rails server` (API QA rows for this PR use RSpec/factories/WebMock; not a live store scrape) |
| Where QA runs | Cloud agents: **headless only**. Mobile: `flutter test` and temporary `test_qa/`. API: RSpec (+ WebMock for OpenGraph). Hotwire Secret Link: RSpec request specs (no browser agent). Simulator / device / `integration_test/` / Maestro / real WhatsApp OG crawl = **owner to run**. |
| Cloud agent scope | May run headless Flutter widget/unit/QA tests and RSpec. Must not use browser/computerUse agents or simulators. Must not hit live Amazon/MercadoLibre (WebMock only). |
| Owner-only parts | iOS/Android simulator or device; `integration_test/`; Maestro; real-device image gallery pick; real WhatsApp/Telegram OG card for Secret Link; live store URL scrape outside WebMock |
| Test data (this PR) | Mocked `ApiClient` transport / in-memory fakes for Flutter. RSpec factories for wishlists/items; WebMock HTML fixtures for OG. **No seeded staging API** required for cloud QA. Multipart image fixtures: small PNG/JPEG generated in-process (libvips) under 2MB. |
| Reset | N/A for mocks; Flutter tests use fresh `InMemoryTokenStorage` per case. RSpec uses transactional fixtures/factories. ActiveStorage test service disk under `tmp/storage` (ephemeral). |
| Accounts / roles | **guest** (unauthenticated Secret Link / OG); **authenticated member** (owner / friend / sharee via factories or mock profile). No admin on mobile. Never store passwords in this profile. |
| Required env var **names** | `API_BASE_URL` (optional in Flutter debug; required `https://` in release). Backend test DB per `backend/` conventions when RSpec API rows run. |

## Section C. Tests

| Field | Value |
| :--- | :--- |
| QA test command (mobile) | `cd mobile && flutter test test_qa` (temporary QA folder; not the main suite) |
| QA test command (API) | `cd backend && bundle exec rspec` (when matrix includes API / Hotwire / OG / media rows) |
| Project suite (regression) | `cd mobile && flutter test` and `flutter analyze`; `cd backend && bundle exec rspec` |
| Screenshots | `tmp/qa-screenshots/` — **never committed** |
| First surfaces to cover | **Sprint 4 focus:** `WishlistDetailScreen` (item list + specs box), `ItemFormScreen` (paste-URL preview confirm, optional price, priority, links), `POST /api/v1/link_previews`, nested items CRUD/reorder/restore, multipart image attach (API), Hotwire `/s/:share_token` guest OG vs authenticated read-only items. **Regression smoke:** `LoginScreen`, `SignUpScreen`, `MyWishlistsScreen`, `SharedWishlistsScreen`. Prior auth/social screens remain in suite but are not first Sprint 4 focus. |
| Locales | `es` (default), `en` (second-locale rule) for Flutter item strings |

## Section D. Limits

| Field | Value |
| :--- | :--- |
| Never touch | Production data; live user accounts; production API without mocks; live storefront HTML outside WebMock |
| Forbidden actions | Send real email or push; payments/charges; delete production records; launch browser or computerUse agents; follow SSRF-like URLs to private/link-local/metadata IPs in live checks |

## Notes

- Temporary QA tests live under `mobile/test_qa/` (or equivalent path named in the matrix) and are removed after the pass unless the owner asks to keep them.
- Reviewer records are staged in the active session file under `## QA reviewer record` and are immutable once written (delivery marker only may change).
- **Sprint 4 Flutter gap:** no local gallery / multipart image picker in the app UI yet. Cloud QA must not mark gallery-upload rows as passed; list them **owner to run** or **n/a — gap** until shipped. API multipart + OG `confirmed_preview` image attach remain in-scope for API rows.
- **Secret Link:** Guest WhatsApp-style OG must stay invitation-only (no item titles/images). Authenticated viewers may see a read-only item list on Hotwire.
- **Client-side image compression:** deferred (O6A) to Sprint 9 — out of Sprint 4 QA scope.
