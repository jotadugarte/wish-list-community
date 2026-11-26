# Changelog

## Unreleased

### Added
- Sprint 3 wishlists: anti-stalking `friends` / `shared` privacy, Secret Link (`/s/:share_token`) Hotwire invitation with allowlisted login/signup `return_to`, owner CRUD + token rotate API, Shared-with-me and friend discovery endpoints, Flutter My/Shared/friend wishlist surfaces with bilingual `AppStrings`.
- Account soft-delete cascades owned wishlists; restore revives only IDs recorded in `user.soft_deleted` AuditEvent metadata.

### Security
- `share_token` is omitted from non-owner API payloads.
- Web session cookies set `Secure` in production (with HttpOnly + SameSite=Lax).
