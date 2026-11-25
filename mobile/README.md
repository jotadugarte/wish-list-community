# Wish List Community — Mobile (Flutter)

iOS + Android client for the Wish List Community platform. It is a thin client:
all business logic, privacy rules and permissions live on the Rails server and are
consumed through `/api/v1`.

## Run

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://your-server.example.com
```

`API_BASE_URL` is optional in development: it defaults to `http://10.0.2.2:3000` on
Android emulators and `http://localhost:3000` elsewhere. **Release builds require an
`https://` URL.**

## Quality checks (also run in CI as the `flutter_test` job)

```bash
flutter analyze
flutter test
```

## Structure

| Path | Purpose |
| :--- | :--- |
| `lib/core/values/` | Dart Value Objects (`EmailAddressVo`, `UsernameVo`, `SearchQueryVo`, `ReportReasonVo`) |
| `lib/core/network/` | `ApiClient` (Bearer auth, 15s timeout, 401 handling), token storage (`SecureTokenStorage` in production, `InMemoryTokenStorage` in tests), `resolveApiBaseUrl` |
| `lib/core/i18n/` | `AppStrings` (`es` / `en`) and friendly error mapping |
| `lib/core/theme/` | `DesignTokens`, `AppTheme`, `AppIconBadge`, `AppNavigationShell` |
| `lib/features/auth/` | Login, profile, logout, account soft-delete / restore |
| `lib/features/social/` | Anti-stalking `@username` search, friendships, block, report |

## Changing the visual identity (design tokens)

All colours, fonts, icon style and navigation layout come from
`lib/core/theme/design_tokens.dart`. It already contains the 20 palettes (light and
dark), 12 font pairings, 8 icon badge styles and 4 navigation layouts from the design
studio (`docs/estudio_diseno_visual_ceci_nata.html`). To apply the co-founders' final
choices, update the `active*` constants at the top of `DesignTokens`
(`activePaletteId`, `activeTypographyId`, `activeIconStyleId`,
`activeNavStructureId`, `activeAppName`) — no screen needs to change.
