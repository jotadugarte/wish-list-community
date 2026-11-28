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

| BM-ITEM-001 | Owner + kept wishlist | Create/list/update/delete/restore item via API | CRUD succeeds; soft-delete hides from kept | API | REQ-ITEM-001, REQ-LIFE-001 | `spec/requests/api/v1/items_spec.rb` | automated |
| BM-ITEM-002 | Accepted friend; wishlist `friends` | `GET .../items` | Friend sees items | API / Policy | REQ-WISH-001, REQ-ITEM-001 | `spec/requests/api/v1/items_spec.rb`, `spec/policies/item_policy_spec.rb` | automated |
| BM-ITEM-003 | Stranger or blocked | Index/show item | 404 / deny | API / Policy | REQ-BLOCK-001 | `spec/requests/api/v1/items_spec.rb` | automated |
| BM-ITEM-004 | Owner uploads image | Attach via processor | ≤3; WebP; ≤1600; EXIF stripped | Service | REQ-ITEM-002 | `spec/services/item_image_processor_spec.rb` | automated |
| BM-ITEM-005 | ItemLink with javascript: URL | Create link | Validation error | Domain | REQ-ITEM-001 | `spec/models/item_link_spec.rb` | automated |
| BM-ITEM-006 | Auth user; mocked store HTML | `POST /link_previews` | Returns og title/image | API | REQ-ITEM-006 | `spec/requests/api/v1/link_previews_spec.rb` | automated |
| BM-ITEM-007 | SSRF URL (127.0.0.1 / 10/8 / metadata) | OpenGraphPreview.fetch | Empty fields; no connect | Service | REQ-ITEM-006 | `spec/services/open_graph_preview_spec.rb` | automated |
| BM-ITEM-008 | Wishlist with items | Soft-delete wishlist | Items discarded | Domain | REQ-LIFE-001 | `spec/models/wishlist_item_cascade_spec.rb` | automated |
| BM-ITEM-009 | Cascaded soft-delete | Restore wishlist | Cascaded items restored; no reservations | Domain | REQ-LIFE-001 | `spec/models/wishlist_item_cascade_spec.rb` | automated |
| BM-ITEM-010 | Invalid priority | Create item | RecordInvalid | Domain | REQ-ITEM-003 | `spec/models/item_spec.rb` | automated |
| BM-ITEM-011 | Guest Secret Link + items exist | `GET /s/:token` | Invitation OG; no item titles | Web | REQ-WISH-005 | `spec/requests/secret_links_items_spec.rb` | automated |
| BM-ITEM-012 | Logged-in sharee | `GET /s/:token` | Read-only item list | Web | REQ-ITEM-001, O1A | `spec/requests/secret_links_items_spec.rb` | automated |

| BM-RES-001 | Friend with access; item free | `POST .../reservations` | Creates active reservation | API | REQ-RES-001 | `spec/requests/api/v1/reservations_spec.rb` | automated |
| BM-RES-002 | Item already held | Second user reserves | **409** Conflict | API | REQ-ARCH-003 | `spec/requests/api/v1/reservations_spec.rb` | automated |
| BM-RES-003 | Non-owner viewer | Item JSON | `availability` present; owner omits | API | REQ-RES-002 | `spec/models/item_availability_spec.rb` | automated |
| BM-RES-004 | Reserver | `GET /my_reservations` | Lists active/grace | API | REQ-RES-004 | `spec/requests/api/v1/my_reservations_spec.rb` | automated |
| BM-RES-005 | Soft-delete reserved item | Soft-delete | Hold canceled; no ghost on restore | Domain | REQ-LIFE-001 | `spec/models/reservation_cleanup_spec.rb` | automated |
| BM-RES-006 | Due estimated_date | Sweep job | → expired_grace + notify | Job | REQ-RES-006 | `spec/jobs/reservation_grace_sweep_job_spec.rb` | automated |
| BM-RES-007 | Logged-in Secret Link sharee | Reserve/extend/cancel on `/s/:token` | Parity with API (O4B) | Web | REQ-RES-001 | `spec/requests/secret_link_reservations_spec.rb` | automated |
| BM-NOTIF-001 | Dispatcher | dispatch S5 event | In-app + email enqueue; push via adapter when tokens/keys present | Service | REQ-NOTIF-001 | `spec/services/notification_dispatcher_spec.rb`, `spec/services/notification_dispatcher_push_spec.rb` | automated |
| BM-NOTIF-002 | Friendship request! / accept! | Dispatch | Recipient gets request_received; requester gets request_accepted; prefs honored | Domain | REQ-NOTIF-001, REQ-SOC-001 | `spec/models/friendship_notifications_spec.rb` | automated |
| BM-NOTIF-003 | Prefs API | `GET/PATCH /notification_preferences` | O7A `defaults_events` includes friend + gift keys; channel toggles persist | API | REQ-NOTIF-001 | `spec/requests/api/v1/notifications_spec.rb` | automated |
| BM-NOTIF-004 | Logout with FCM bound | `DELETE /session` | DeviceTokens for token destroyed | API | REQ-NOTIF-002 | session/device_token specs | automated |
| BM-MOB-001 | Logged-in share text with https URL; last wishlist still owned | ShareIntentCoordinator | skipPicker → Add Item with payload | Flutter | REQ-MOB-001, REQ-MOB-002, REQ-ITEM-006 | `mobile/test/features/share/share_intent_coordinator_test.dart` | automated |
| BM-MOB-002 | Logged-out share | ShareIntentCoordinator | requireLogin; payload retained for resume | Flutter | REQ-MOB-001 | `mobile/test/features/share/share_intent_coordinator_test.dart` | automated |
| BM-MOB-003 | Deep link `/u/:user` or `/s/:token` | DeepLinkTarget/Router | Routes friendProfile or secretLink | Flutter | REQ-MOB-001 | `mobile/test/core/values/deep_link_target_test.dart`, `deep_link_router_test.dart` | automated |
| BM-MOB-004 | Deep link `/a/:token` | DeepLinkTarget/Router | Routes activityLink; unknown paths safeFailure | Flutter | REQ-MOB-001, REQ-ACT-001 | same | automated |
| BM-ACT-001 | Creator creates activity | `POST /api/v1/activities` | Opaque share_token; creator accepted co-org | API | REQ-ACT-001 | `spec/requests/api/v1/activities_spec.rb` | automated |
| BM-ACT-002 | First invitee accepts | Accept invite | Money/visibility settings freeze (O2B) | Domain | REQ-ACT-001 | `spec/models/activity_freeze_spec.rb` | automated |
| BM-ACT-003 | ≥3 accepted; secret_santa | Draw | Single Hamiltonian cycle; assignment private to giver | Service / API | REQ-ACT-001, REQ-ACT-004 | `spec/services/activity_draw_service_spec.rb` | automated |
| BM-ACT-004 | Sealed secret_santa leave/block | Leave or Block Wins | `needs_dropout_recovery`; Blind Bridge or Full Redraw | Service | REQ-ACT-003, REQ-BLOCK-001 | `spec/services/activity_dropout_bridge_service_spec.rb`, `spec/policies/activity_policy_spec.rb` | automated |
| BM-ACT-005 | Guest opens `/a/:token` | Hotwire preview | Safe invite; no roster leak | Web | REQ-ACT-001 | `spec/requests/activity_links_spec.rb` | automated |
| BM-ACT-006 | Invitee accepts | Ensure activity wishlist | One `Wishlist` with `activity_id`; not in personal My Wishlists; no `share_token` | Domain / API | REQ-ARCH-002, REQ-ACT-001 | `spec/services/activity_wishlist_ensure_service_spec.rb`, `spec/requests/api/v1/activity_b_surfaces_spec.rb` | automated |
| BM-ACT-007 | Owner adds activity item; budget mode set | Create/update item | Currency = activity; `BudgetEnforcement` blocks invalid/missing price; `none` allows any | Domain / API | REQ-ACT-005 | `spec/services/budget_enforcement_spec.rb`, `spec/requests/api/v1/activity_b_surfaces_spec.rb` | automated |
| BM-ACT-008 | Sealed activity; peer may view | Reserve peer item | Gate allows; pre-seal reserve forbidden; no self-reserve; SS recipient_only honors assignment | Domain / API | REQ-ACT-001 | `spec/services/activity_visibility_gate_spec.rb` | automated |
| BM-ACT-009 | open_gifting pre-seal; creator sets N | `PATCH .../reservation_limit` | All activity wishlists get `max_reservations_per_user=N`; **422** after seal; SS stays 1 | API / Service | REQ-RES-005 | `spec/services/activity_reservation_limit_service_spec.rb`, `spec/requests/api/v1/activity_b_surfaces_spec.rb` | automated |
| BM-ACT-010 | Sealed; under limit | Reserve / extend / cancel / Path 1–2 / grace on activity item | Same semantics as personal; `my_reservations` includes `activity_id` | API | REQ-RES-001, REQ-RES-004, REQ-RES-006, REQ-GIFT-001 | `spec/requests/api/v1/activity_b_surfaces_spec.rb` | automated |
| BM-ACT-011 | Leave / cancel activity / Block Wins | Cleanup hooks | Cancel open holds; void open gifts; archive leaver activity wishlist; notify | Domain | REQ-ACT-003, REQ-BLOCK-001, REQ-LIFE-001 | `spec/services/activity_fc2a_cleanup_spec.rb` | automated |
| BM-ACT-012 | Activity B event (reserve/gift/budget) | `ActivityNotifier` + prefs | Activity-scoped keys in `DEFAULT_EVENTS`; inbox/email/push via dispatcher | Service | REQ-NOTIF-001 | `spec/services/activity_b_notifier_spec.rb` | automated |
| BM-ACT-013 | Member board; activity lists | Hotwire `/app/activities/:id` | Lists/items/reserve/gift on board only; budget errors visible; no Secret Link UI | Web | REQ-ACT-001, REQ-ACT-005 | `spec/requests/member/activity_b_surfaces_spec.rb` | automated |
| BM-ACT-014 | Flutter activity board | Activity B feature tests | List/item forms with price; reserve/gift/grace; limit/budget errors; board-only nav | Flutter | REQ-MOB-001, REQ-ACT-005 | `mobile/test/features/activities/` | automated |
| BM-MOB-005 | Client image before upload | ImageCompressor | Best-effort ≤2MB / ≤1600; max 3; server libvips still mandatory | Flutter | REQ-MOB-001, REQ-ITEM-002 | image compressor tests | automated |
| BM-WEB-001 | Guest | `GET /terms`, `GET /privacy` | 200 public bilingual content | Web | REQ-AUTH-002, REQ-LIFE-002 | `spec/requests/legal_pages_spec.rb` | automated |
| BM-WEB-002 | Logged-in member | `GET /app` shell | Nav sections lists/shared/friends/reservations/notifications/settings | Web | REQ-ARCH-001 | MemberWebShell request specs | automated |

