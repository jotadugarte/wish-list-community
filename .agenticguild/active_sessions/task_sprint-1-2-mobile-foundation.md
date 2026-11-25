# Active Session: MVP Sprint 1 & Sprint 2 (Mobile Foundation & Social Screens)

<session_metadata>
  <task_name>sprint-1-2-mobile-foundation</task_name>
  <classification>Feature</classification>
  <roadmap_item>MVP Sprint 1 (Mobile Foundation) — Flutter Base + Design System & MVP Sprint 2 (Mobile) — Social & Anti-Stalking Profile Search (Flutter Screens)</roadmap_item>
  <branch>feat/sprint-1-2-mobile-foundation</branch>
  <started_at>2026-11-25</started_at>
  <req_ids>REQ-ARCH-001, REQ-AUTH-001, REQ-AUTH-002, REQ-AUTH-003, REQ-USER-001, REQ-USER-002, REQ-USER-003, REQ-BLOCK-001, REQ-LIFE-002, REQ-SOC-001, REQ-WISH-001, REQ-DISC-001</req_ids>
</session_metadata>

## Task Description
Build the complete Flutter mobile foundation (`mobile/`) covering **MVP Sprint 1 (Mobile Foundation)** and **MVP Sprint 2 (Mobile Social & Anti-Stalking Profile Search)**, strictly decoupled from pending visual overrides via a single centralized `DesignTokens` configuration (`mobile/lib/core/theme/design_tokens.dart`) that mirrors all 20 palettes, 12 font pairings, 8 icon badge styles, and 4 navigation layouts from Ceci ("Ñata")'s Design Studio:
1. **Flutter Project Bootstrap & Centralized Parameterized Design System (`mobile/lib/core/theme/`)** (`REQ-ARCH-001`):
   - `design_tokens.dart` & `app_theme.dart`: Centralized `DesignTokens` (`paletteId`, `typographyId`, `iconStyleId`, `navStructureId`, `appName`, Light & Dark color tokens, `AppIconBadge` widget, and adaptive `AppNavigationShell` supporting the 4 navigation structures). Updating the active IDs in `DesignTokens` switches the entire app's visual identity in one place.
2. **Domain Value Objects in Dart (`mobile/lib/core/values/`)** (`REQ-USER-001`, `REQ-AUTH-001`, `REQ-SOC-001`, `REQ-DISC-001`):
   - `EmailAddressVo`, `UsernameVo`, `SearchQueryVo`, and `ReportReasonVo` enforcing the exact same Correct-by-Construction invariants on the client before network calls, while keeping the Rails 8 server as the ultimate authority.
3. **API v1 HTTP Client, Auth Token Storage & Session State (`mobile/lib/core/network/` & `mobile/lib/features/auth/`)** (`REQ-AUTH-001`, `REQ-AUTH-002`, `REQ-AUTH-003`, `REQ-LIFE-002`, `REQ-USER-002`):
   - `ApiClient` sending `Authorization: Bearer <token>` and `Accept: application/json`, mapping `401`, `404`, `409`, and `422` deterministically.
   - `AuthRepository` & `AuthController` handling Login (`POST /api/v1/session`), Logout (`DELETE /api/v1/session`), Password Reset (`POST /api/v1/passwords`), Profile (`GET /api/v1/me`), Soft-Delete Account (`DELETE /api/v1/account`), and 30-day Account Restore (`POST /api/v1/account/restore`).
   - Authentication UI screens (`LoginScreen`, `PasswordResetScreen`, `AccountRestoreScreen`, `ProfileSettingsScreen`) with bilingual `es`/`en` strings (`AppStrings`).
4. **Sprint 2 Social Graph & Anti-Stalking Search Screens (`mobile/lib/features/social/`)** (`REQ-SOC-001`, `REQ-WISH-001`, `REQ-BLOCK-001`, `REQ-DISC-001`):
   - `SocialRepository` consuming `GET /api/v1/users/search?q=...`, `GET /api/v1/users/:username`, `GET/POST/PATCH/DELETE /api/v1/friendships`, `POST /api/v1/user_blocks`, and `POST /api/v1/reports`.
   - `UserSearchScreen` (anti-stalking `@username` search showing only public handle and friendship action button, never personal wishlists to non-friends).
   - `FriendsListScreen` (tabs/sections for accepted friends, incoming pending requests with Accept/Decline, and outgoing pending requests with Cancel, plus Block and Report user actions).

## Domain Model
- `EmailAddressVo` (`mobile/lib/core/values/domain_values.dart`): Immutable Value Object normalizing email addresses, enforcing RFC format and `<= 254` length, and redacting `toString()`.
- `UsernameVo` (`mobile/lib/core/values/domain_values.dart`): Immutable Value Object normalizing `@username` handles (`3..30` chars, `^[a-z0-9_]+$`, non-reserved words).
- `SearchQueryVo` (`mobile/lib/core/values/domain_values.dart`): Immutable Value Object normalizing `@username` prefix queries (`2..30` chars, `^[a-z0-9_.]+$`).
- `ReportReasonVo` (`mobile/lib/core/values/domain_values.dart`): Immutable Value Object validating abuse report reasons (`spam`, `harassment`, `impersonation`, `inappropriate_content`, `scam`).

## Core Function Contracts (Pre-conditions & Post-conditions)
- `DesignTokens.forConfiguration({paletteId, typographyId, iconStyleId, navStructureId, isDark})`:
  - **Pre-condition:** IDs are non-empty strings (falling back deterministically to default preset `"01"` / `"A"` if unknown).
  - **Post-condition:** Returns a valid, immutable `DesignTokens` instance with complete non-null color, typography, icon, and navigation tokens.
- `AuthRepository.login({email, password, deviceName, fcmToken})`:
  - **Pre-condition:** `EmailAddressVo(email)` is valid and `password` is non-empty.
  - **Post-condition:** Persists the raw bearer token in `TokenStorage` and returns an authenticated `UserProfile`.
- `SocialRepository.searchUsers(rawQuery)`:
  - **Pre-condition:** `SearchQueryVo(rawQuery)` is valid (`2..30` valid handle characters).
  - **Post-condition:** Returns bounded list (`<= 20`) of `PublicUserCard` instances with `friendshipStatus`.

<implementation_plan>
  <step id="1" status="complete">Initialize the Flutter project in `mobile/`, write failing `flutter test` unit tests for Dart Domain Value Objects (`test/core/values/domain_values_test.dart`: `EmailAddressVo`, `UsernameVo`, `SearchQueryVo`, `ReportReasonVo`), then implement the Value Objects (`[REQ-ARCH-001]`, `[REQ-USER-001]`, `[REQ-SOC-001]`, `[REQ-DISC-001]`).</step>
  <step id="2" status="pending">Write failing `flutter test` unit & widget tests for the Parameterized Design System (`test/core/theme/design_tokens_test.dart`) covering palette switching, light/dark modes, `AppIconBadge`, and `AppNavigationShell` layouts, then implement `design_tokens.dart`, `app_theme.dart`, `app_icon_badge.dart`, and `app_navigation_shell.dart` (`[REQ-ARCH-001]`, `[REQ-USER-002]`).</step>
  <step id="3" status="pending">Write failing `flutter test` unit tests for `ApiClient` and `AuthRepository` (`test/features/auth/auth_repository_test.dart`) covering login, logout, `/api/v1/me`, password reset, account soft-delete, and 30-day restore, then implement `ApiClient`, `TokenStorage`, `UserProfile`, and `AuthRepository` (`[REQ-AUTH-001]`, `[REQ-AUTH-003]`, `[REQ-LIFE-002]`).</step>
  <step id="4" status="pending">Write failing `flutter test` unit tests for `SocialRepository` (`test/features/social/social_repository_test.dart`) covering anti-stalking `@username` search, friend request send/accept/remove, user blocking, and user abuse reporting, then implement `PublicUserCard`, `FriendshipItem`, and `SocialRepository` (`[REQ-SOC-001]`, `[REQ-WISH-001]`, `[REQ-BLOCK-001]`, `[REQ-DISC-001]`).</step>
  <step id="5" status="pending">Write failing `flutter test` widget tests for the Sprint 1 & Sprint 2 Mobile Screens (`test/features/app_screens_test.dart`) verifying Login, Anti-Stalking `@username` Search, Friends & Requests management, and Block/Report dialogs, then implement `LoginScreen`, `UserSearchScreen`, `FriendsListScreen`, `ProfileSettingsScreen`, and `WishListApp` root (`[REQ-AUTH-001]`, `[REQ-SOC-001]`, `[REQ-WISH-001]`, `[REQ-BLOCK-001]`).</step>
</implementation_plan>
