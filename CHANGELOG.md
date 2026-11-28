# Changelog

## Unreleased

### Added
- Sprint 9 Mobile Wrap-Up (PR #16): Flutter Share-to-App + deep links (friend/secret), client image compress + multipart, FCM bind/rebind/unbind, inbox + notification prefs; Hotwire Member `/app` shell parity; public bilingual `/terms` `/privacy`. Ops follow-ups: prod host swap, Google FCM keys, legal-text approval, owner device QA.
- Admin Brand / Style Guide (PR #17): admin-only `GET /admin/style_guide` with shared `design/design_tokens.json` (web preview + HTML phone mock; Flutter additive catalog reader).
- Sprint 8 Admin/Moderation (web-only Hotwire `/admin`): report triage (dismiss / suspend / soft-delete), Suspend with generic auth failures (FC2), audit viewer with O4A compensating reverts, admin-only gift detail (gifter + `purchase_link_ref`), SoftDeletable `admin_enforcement` gate so members cannot undo admin soft-deletes.
- Sprint 7 anti-spam: wishlist abuse reports for accessible non-owner viewers (API + Hotwire Secret Link Reportar lista + Flutter), pending uniqueness + `AuditEvent` `report.created` (no owner notify), Rails 8 `rate_limit` on API/Hotwire write mutations with named buckets and user-id keying, localized report reasons, clear 429 / wait UX.
- Sprint 6 dual-path gift fulfillment: Path 1 (mark purchased → delivered → owner confirm) and Path 2 (owner mark received), optional anonymous thank-you, Received Gifts section, O8D void on item delete/block/unfriend with `confirm_void_gifts`, Hotwire Secret Link + Flutter parity, admin-only `purchase_link_ref`.
- Sprint 5 secret reservations: create/extend/cancel with partial unique index + 409 race, viewer-relative `availability`, `GET /my_reservations`, soft-delete/block/unfriend/account cancel hooks, `ReservationGraceSweepJob` (72h grace → auto-release), notification foundation (in-app + email enqueue; push no-op), Hotwire Secret Link reserve parity (O4B), Flutter My Reservations + reserve CTA.
- Sprint 4 items + media: `Item` / `ItemLink` CRUD + reorder, SoftDeletable cascade with wishlists, ActiveStorage images (WebP + EXIF/GPS strip), SSRF-safe OpenGraph link previews with owner confirm-before-persist, Hotwire Secret Link read-only items, Flutter wishlist detail + `ItemFormScreen`.
- Sprint 3 wishlists: anti-stalking `friends` / `shared` privacy, Secret Link (`/s/:share_token`) Hotwire invitation with allowlisted login/signup `return_to`, owner CRUD + token rotate API, Shared-with-me and friend discovery endpoints, Flutter My/Shared/friend wishlist surfaces with bilingual `AppStrings`.
- Account soft-delete cascades owned wishlists; restore revives only IDs recorded in `user.soft_deleted` AuditEvent metadata.

### Security
- OpenGraph fetch/download blocks private, link-local, metadata, and IPv4-mapped IPv6 addresses.
- `share_token` is omitted from non-owner API payloads.
- Web session cookies set `Secure` in production (with HttpOnly + SameSite=Lax).
