Project Roadmap
Things done and things left to do. Update this when finishing branches; use `roadmap-manage` to add, prioritize, or catalog items.
Format: Use `[x]` for done, `[ ]` for pending. Add `(REQ-ID)` to link to SPEC. Add `— YYYY-MM-DD` for done date. Add `— Branch: name` for in-progress. Add `— Depends on: Item` for dependencies.
---
Technical decisions
Backend and web: Ruby on Rails 8 + PostgreSQL (server-rendered HTML + Hotwire)
Mobile (iOS and Android): Flutter, consuming the `/api/v1` API
JS built into the framework (Hotwire: Turbo + Stimulus) is accepted; no custom JS except for rare cases
Business logic and permissions live only on the server; web and Flutter are clients
Admin panel is web only (Rails), no mobile version
Done
(No completed items yet)
In Progress
(No items currently in progress)
Pending (by priority)
[ ] MVP Sprint 1 — Base + Auth + API
[ ] Rails 8 + PostgreSQL project, Solid Queue, Hotwire (importmap)
[ ] Versioned API `/api/v1` with token authentication (web uses cookie sessions)
[ ] Central permissions layer (Pundit or custom policies): blocking, friendship, privacy, secret link, reservations
[ ] Initial Flutter project + shared design system (colors, typography, icons, spacing)
[ ] Authentication (sign up, login, logout, sessions) using the native Rails 8 generator; tokens for the API
[ ] Reset password (MVP; email confirmation is left for v1)
[ ] Public profile: unique `username` (email stays private), change with cooldown
[ ] Block users (block wins: immediately cuts access even if there was a friendship/share/link)
[ ] Soft-delete + restore (wishlist restores its items; restoring leaves no "ghost reservations")
[ ] MVP Sprint 2 — Social
[ ] Search users by `username`
[ ] Friend requests + accept/decline + friends list (friends only in MVP)
[ ] Report user (MVP: reports only; full moderation in Sprint 8)
[ ] API v1 endpoints + Flutter screens for this sprint
[ ] MVP Sprint 3 — Wishlists (privacy + sharing)
[ ] Wishlist CRUD
[ ] Privacy per wishlist:
[ ] Public: visible in Discover and by link
[ ] Private: visible to friends only
[ ] Shared: specific friends only + secret link
[ ] Secret link (does not expire); automatically invalidated when the wishlist becomes "private"
[ ] Guests can view public wishlists (Discover and by link); they cannot reserve/gift
[ ] API v1 endpoints + Flutter screens for this sprint
[ ] MVP Sprint 4 — Items + media
[ ] Item CRUD with notes (size/color) and multiple links per item
[ ] Up to 3 images per item:
[ ] Max 2MB each, max 1600px on the longest side
[ ] Optional client-side compression (UX)
[ ] Mandatory server-side resize + re-encode (WebP when possible; PNG allowed and converted to WebP when applicable)
[ ] API v1 endpoints + Flutter screens for this sprint
[ ] MVP Sprint 5 — Reservations (private)
[ ] Reserve an item (logged-in users with access only) with "first to reserve wins" concurrency
[ ] One active reservation per item
[ ] Enforced by a partial unique index in PostgreSQL (one active reservation per item)
[ ] Private note from the reserver (nobody else sees it)
[ ] Private estimated date from the reserver (the recipient never sees reservations)
[ ] If the date expires: notify the reserver "Date expired"; the reserver decides to extend the date or remove the reservation (no auto-release)
[ ] API v1 endpoints + Flutter screens for this sprint
[ ] MVP Sprint 6 — Gifted + anonymity + conflict resolution
[ ] Mark an item as "gifted" (owner or gifter), even if nobody reserved it
[ ] Anonymous for users; admin can audit
[ ] When marking as "gifted":
[ ] Cancel the active/expired reservation if one exists
[ ] Notify the reserver "Already delivered; reservation removed"
[ ] Store a reference to the link used for an "online" gift (visible to admin only)
[ ] API v1 endpoints + Flutter screens for this sprint
[ ] MVP Sprint 7 — Discover + anti-spam + reports
[ ] Discover (public users + public wishlists), no follow/like
[ ] Rate limits (anti-spam; Rails 8 includes a built-in `rate_limit`) + report wishlist
[ ] Sensitive content: handled through reports only (no automatic review in MVP)
[ ] API v1 endpoints + Flutter screens for this sprint
[ ] MVP Sprint 8 — Admin/Moderation (web only)
[ ] Admin panel: report queue + actions (block)
[ ] Admin can view internal history (reservations/gifts/changes) and revert for error/abuse
[ ] Admin sees the identity of gifters (for auditing) and the link used in an online gift
[ ] MVP Sprint 9 — Mobile wrap-up (Flutter iOS + Android)
[ ] Full MVP parity with the web app in the Flutter apps
[ ] Deep links (Universal Links on iOS, App Links on Android): public profile, public wishlist, secret link
[ ] Image upload from mobile: in-app compression respecting limits (2MB, 1600px, max 3)
[ ] Push notifications via Firebase Cloud Messaging (optional in MVP; email + in-app are required)
[ ] Publication on the App Store and Google Play
[ ] Notifications (MVP) — in-app + email (configurable per user)
[ ] Preferences per event (in-app/email toggles)
[ ] Single dispatcher to create in-app + enqueue email (+ push when available; device tokens table)
[ ] Minimum events:
[ ] Friend request received
[ ] Friend request accepted
[ ] Reservation date expired (reserver only)
[ ] Reservation canceled because the gift was delivered (reserver only)
Backlog
[ ] v1 Sprint A — Activities (configurable system)
[ ] Create a group activity (owner, name, dates, single currency, budget per individual gift)
[ ] Settings when creating an activity:
[ ] `assignment_mode`: `secret_santa` (1→1) / `open_gifting` (everyone to everyone)
[ ] `visibility_mode`: `recipient_only` / `all_participants`
[ ] `reservation_visibility`: `hidden_from_recipient` / `visible_to_recipient`
[ ] Invite friends / accept participants (blocks prevent participation)
[ ] Draw for `secret_santa`
[ ] v1 Sprint B — Activities (lists + reservations + budget)
[ ] Each user adds their activity items (manual price + currency)
[ ] Reservations within an activity (`open_gifting` allows reserving for multiple people)
[ ] Budget validation: do not allow reserving an item with a price above the budget (per individual gift)
[ ] v1 — Email confirmation
[ ] v1 — Share with non-friends
[ ] Share with any user (non-friend) + anti-abuse hardening
[ ] Backlog v1 — Activities: "don't repeat last year's gift" (optional)
[ ] Backlog — Validate price against link (best-effort)
<!--
Example formats:
- [x] Auth & sessions (REQ-AUTH-001) — 2026-02-15
- [ ] User dashboard (REQ-DASH-001) — Branch: feature/dashboard
1. [ ] Export to CSV (REQ-EXPORT-001)
