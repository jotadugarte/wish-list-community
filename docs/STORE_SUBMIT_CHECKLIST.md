# App Store / Play Submit Checklist (Sprint 9 · O8A/O9B/O10B)

Use before filing App Store or Google Play review. Placeholder legal copy and staging host are **not** submit-ready.

## Must complete before submit

- [ ] Swap public host from staging (`staging.wishlist.local` / `PUBLIC_WEB_HOST`) to production domain
- [ ] Update Android App Links host + `assetlinks.json` SHA-256 fingerprints for the release signing key
- [ ] Update iOS Associated Domains + `apple-app-site-association` Team ID / bundle id for production
- [ ] Owner-approved final Terms and Privacy copy (es + en) replacing placeholders on `/terms` and `/privacy`
- [ ] Confirm in-app account soft-delete is reachable (Profile → deactivate) and restore path documented
- [ ] Paste Google / Firebase project keys; verify real-device push (until then: inbox + email only)
- [ ] Privacy Policy URL and Terms URL on store listings point at production HTTPS pages
- [ ] Data safety / App Privacy answers match actual collection (account email, FCM token, optional images)
- [ ] UGC EULA acceptance still required at signup (`terms_accepted`)

## Owner-local manual checks (not covered by CI)

- [ ] Share sheet → app opens Add Item with parsed URL (iOS + Android)
- [ ] Universal / App Link opens friend profile and `/s/:token` secret link
- [ ] Unsupported paths (e.g. `/activities/...`) fail safely
- [ ] Push notification appears on a physical device after keys are present
- [ ] Legal links from Flutter Profile open the correct locale pages

## CI proof (already expected green)

- Backend RSpec
- `flutter analyze` + `flutter test`
