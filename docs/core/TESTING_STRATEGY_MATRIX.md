# Testing Strategy Matrix

**Purpose:** Defines the testing requirements and coverage rules. No feature may be merged without fulfilling these testing contracts.

## 1. Traceability Requirement
* **The `[REQ-ID]` Rule:** EVERY test block (e.g., `it "... [REQ-AUTH-001]"` in RSpec or `test('... [REQ-MOB-001]', ...)` in Flutter) must include the specific `[REQ-ID]` from [SPEC.md](file:///home/jader/proyectos/wish-list-community/docs/core/SPEC.md) that it is verifying. Untraced tests are considered invalid.

## 2. The Testing Pyramid

| Layer | Framework | Rule of Engagement | Target Coverage |
|---|---|---|---|
| **Domain Models, Value Objects & Services** | RSpec (`spec/models`, `spec/services`) | 100% logic & invariant coverage (cooldowns, quarantines, block cascades, 72h grace auto-release, single-cycle Secret Santa draw, blind bridge). Mock all external I/O. | 100% |
| **Authorization Policies (Anti-Stalking & Block Wins)** | RSpec + Pundit Matchers (`spec/policies`) | Test the complete 4-actor Visibility Scenario Matrix (Stranger, Accepted Friend, Secret/Activity Link Guest, Blocked User) for every policy. | 100% |
| **Controllers & `/api/v1` Endpoints** | RSpec Request Specs (`spec/requests`) | Test HTTP status codes, cookie/Bearer SHA-256 auth, anti-spoiler JSON serialization (verifying owner payloads never leak reservation state or mutate `items.updated_at`), rate limits, and `RecordNotUnique` idempotency (`409`). | 95% |
| **Web UI & Hotwire Flows** | RSpec System Specs (`spec/system` with Capybara) | Test key Turbo Frame/Stream interactions, login `return_to` redirect on Secret Links, and Admin moderation flows. | Key Flows (85%+) |
| **Mobile UI & Share Sheet Parsing (`mobile/`)** | `flutter_test` & Widget Tests | Test mixed text+URL Share Sheet extraction (`REQ-MOB-002`), token auth state, and core wishlist/reservation screens. | 85% |

## 3. Mocking, Time & Concurrency Rules
* **External Network & Store Scraping (`OpenGraph`):** MUST be mocked/stubbed in tests (e.g., WebMock). Tests must never make live HTTP calls to Amazon or external stores, and SSRF tests must verify rejection of private IP ranges (`127.0.0.1`, `10.0.0.0/8`, `169.254.169.254`).
* **Time, Cooldowns & Timezones:** MUST be frozen or traveled deterministically using `ActiveSupport::Testing::TimeHelpers` (`freeze_time`, `travel`). **Rails 8.1 Gotcha:** Never nest `travel ... do` or `travel_to ... do` blocks inside a `freeze_time do` block (Rails 8.1 raises `RuntimeError`). Instead, call `freeze_time` without a block, advance time sequentially with `travel N.days`, and always reset in `after { travel_back }`.
* **Randomness (Secret Santa Draw):** Random number generators in draw algorithms MUST accept an explicit deterministic seed in tests to verify single Hamiltonian cycle invariants without flakiness.
