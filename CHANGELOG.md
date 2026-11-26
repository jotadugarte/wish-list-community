# Changelog

## Unreleased

### Added
- Sprint 4 items + media: `Item` / `ItemLink` CRUD + reorder, SoftDeletable cascade with wishlists, ActiveStorage images (WebP + EXIF/GPS strip), SSRF-safe OpenGraph link previews with owner confirm-before-persist, Hotwire Secret Link read-only items, Flutter wishlist detail + `ItemFormScreen`.
- Sprint 3 wishlists: anti-stalking `friends` / `shared` privacy, Secret Link (`/s/:share_token`) Hotwire invitation with allowlisted login/signup `return_to`, owner CRUD + token rotate API, Shared-with-me and friend discovery endpoints, Flutter My/Shared/friend wishlist surfaces with bilingual `AppStrings`.
- Account soft-delete cascades owned wishlists; restore revives only IDs recorded in `user.soft_deleted` AuditEvent metadata.

### Security
- OpenGraph fetch/download blocks private, link-local, metadata, and IPv4-mapped IPv6 addresses.
- `share_token` is omitted from non-owner API payloads.
- Web session cookies set `Secure` in production (with HttpOnly + SameSite=Lax).
