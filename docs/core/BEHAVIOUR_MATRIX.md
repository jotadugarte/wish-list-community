# Behaviour Matrix

**Purpose:** Traceable behaviours the product must exhibit. Used by explore/start-task planning and by finish-branch coverage checks. Status values: `planned`, `automated`, `manual-only`, `n/a`.

**Scope (seed):** MVP Sprint 3 — Wishlist access actors (anti-stalking + Secret Link). Expand in later sprints.

| ID | Preconditions | Steps | Expected result | Layer | Requirement | Test path | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| BM-WISH-001 | Two users; no friendship; wishlist `friends` owned by A | B searches `@A` / opens profile wishlists | No personal wishlists exposed; index empty or 404 per anti-stalking | API / Policy | REQ-WISH-001 | `spec/policies/wishlist_policy_spec.rb`, `spec/requests/api/v1/user_wishlists_spec.rb` | automated |
| BM-WISH-002 | Accepted friendship A↔B; A's wishlist `friends` | B lists `GET /users/:A/wishlists` and `GET /wishlists/:id` | B can view A's `friends` wishlist shell | API / Policy | REQ-WISH-001 | `spec/policies/wishlist_policy_spec.rb`, `spec/requests/api/v1/user_wishlists_spec.rb` | automated |
| BM-WISH-003 | A's wishlist `shared`; B accepted friend but **not** explicit share; no Secret Link | B tries show/index | B **cannot** access (not all-friends; only selected + link) | API / Policy | REQ-WISH-001 | `spec/policies/wishlist_policy_spec.rb` | automated |
| BM-WISH-004 | A's wishlist `shared`; explicit `WishlistShare` for B | B show/index | B can view | API / Policy | REQ-WISH-001 | `spec/policies/wishlist_policy_spec.rb`, `spec/requests/api/v1/wishlists_spec.rb` | automated |
| BM-WISH-005 | Valid `share_token`; guest (no session) | `GET /s/:share_token` | Invitation HTML + OG *Lista de deseos de @owner*; **no** item data; login/signup CTAs with `return_to` | Web / Hotwire | REQ-WISH-005 | `spec/requests/secret_links_spec.rb` | automated |
| BM-WISH-006 | Valid token; logged-in C; no block | C opens `/s/:token` | Upsert `WishlistShare(source: secret_link)`; empty shell; appears in Shared with me | Web + API | REQ-WISH-002, REQ-WISH-003 | `spec/requests/secret_links_spec.rb`, `spec/requests/api/v1/shared_wishlists_spec.rb` | automated |
| BM-WISH-007 | Valid token; guest then web login/signup with allowlisted `return_to` | Complete auth | Redirect back to `/s/:token`; Shared with me registered | Web | REQ-WISH-005, REQ-AUTH-001 | `spec/requests/secret_link_return_to_spec.rb` | automated |
| BM-WISH-008 | Block either direction between viewer and owner; valid token or friend | Any wishlist / Secret Link access | **404** / deny (Block Wins) | Policy / Web / API | REQ-BLOCK-001 | `spec/policies/wishlist_policy_spec.rb`, `spec/requests/secret_links_spec.rb` | automated |
| BM-WISH-009 | Wishlist `shared` with token; owner switches to `friends` | Open old `/s/:old_token`; list prior `secret_link` shares | Token nil; old URL 404; secret_link shares revoked | Domain / Web | REQ-WISH-002 | `spec/models/wishlist_spec.rb`, `spec/requests/secret_links_spec.rb` | automated |
| BM-WISH-010 | Wishlist `shared`; owner rotates token (O4A) | Old URL; new URL; explicit shares | Old 404; new works; explicit shares kept; secret_link shares revoked | Domain / API | REQ-WISH-002, REQ-WISH-006 | `spec/requests/api/v1/wishlists_spec.rb` | automated |
| BM-WISH-011 | Owner creates wishlist (no privacy override) | `POST /api/v1/wishlists` | `privacy_mode=friends`; `share_token` nil | API | REQ-WISH-001 (O2A) | `spec/requests/api/v1/wishlists_spec.rb` | automated |
| BM-WISH-012 | Soft-deleted wishlist; valid former token | `GET /s/:token` or API show | 404; no OG private leak | Web / API | REQ-LIFE-001, REQ-WISH-005 | `spec/requests/secret_links_spec.rb` | automated |
| BM-WISH-013 | Explicit share exists; users unfriend | Friendship remove | `WishlistShare`s between pair deleted | Domain | REQ-BLOCK-002 (parity), L-unfriend-shares | `spec/models/wishlist_share_spec.rb` | automated |
| BM-WISH-014 | Owner opens own Secret Link while logged in | `GET /s/:own_token` | Owner shell; **no** self `WishlistShare` row | Web | REQ-WISH-003 | `spec/requests/secret_links_spec.rb` | automated |
| BM-WISH-015 | Attacker crafts `return_to=//evil` or off-allowlist path | Web login/signup | Reject; no open redirect | Web | REQ-WISH-005 | `spec/requests/secret_link_return_to_spec.rb` | automated |
