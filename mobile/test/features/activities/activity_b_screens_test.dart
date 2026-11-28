import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/activities/activity_board_screen.dart';
import 'package:wish_list_mobile/features/activities/activity_repository.dart';
import 'package:wish_list_mobile/features/gifts/gift_repository.dart';
import 'package:wish_list_mobile/features/notifications/notification_prefs_screen.dart';
import 'package:wish_list_mobile/features/notifications/notification_repository.dart';
import 'package:wish_list_mobile/features/reservations/reservation_repository.dart';
import 'package:wish_list_mobile/features/wishlists/my_wishlists_screen.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_repository.dart';

void main() {
  group('Activity B screens [REQ-MOB-001] [REQ-ACT-001] O1B FC1A', () {
    late InMemoryTokenStorage tokenStorage;
    final strings = AppStrings.forLocale('es');
    final tokens = DesignTokens.forConfiguration();

    ApiClient buildClient(ApiResponse Function(RecordedApiRequest req) responder) {
      return ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async => responder(req),
      );
    }

    Map<String, dynamic> activityJson({String status = 'sealed'}) {
      return {
        'id': 7,
        'name': 'Grupo B',
        'currency': 'CRC',
        'assignment_mode': 'open_gifting',
        'visibility_mode': 'all_participants',
        'reservation_visibility': 'visible_to_recipient',
        'budget_mode': 'none',
        'status': status,
        'needs_dropout_recovery': false,
        'viewer_status': 'accepted',
        'viewer_can_manage': false,
        'creator': {'id': 1, 'username': 'host'},
      };
    }

    setUp(() async {
      tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('tok');
    });

    testWidgets('board shows activity list item form with price [REQ-ACT-005] FC1A', (
      tester,
    ) async {
      final client = buildClient((req) {
        if (req.path.endsWith('/my_assignment')) {
          return const ApiResponse(statusCode: 200, body: {'assignment': null});
        }
        if (req.path == '/api/v1/activities/7/wishlists') {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'wishlists': [
                {
                  'id': 11,
                  'title': 'Lista Ana',
                  'activity_id': 7,
                  'privacy_mode': 'friends',
                  'owner': {'id': 2, 'username': 'ana'},
                  'viewer_is_owner': true,
                },
              ],
            },
          );
        }
        if (req.path == '/api/v1/activities/7/wishlists/11/items' &&
            req.method == 'GET') {
          return const ApiResponse(statusCode: 200, body: {'items': []});
        }
        if (req.path == '/api/v1/activities/7') {
          return ApiResponse(statusCode: 200, body: {'activity': activityJson()});
        }
        return const ApiResponse(statusCode: 200, body: {});
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityBoardScreen(
            activityRepository: ActivityRepository(apiClient: client),
            reservationRepository: ReservationRepository(apiClient: client),
            giftRepository: GiftRepository(apiClient: client),
            strings: strings,
            tokens: tokens,
            activityId: 7,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.activityListsHeading), findsOneWidget);
      expect(find.text('Lista Ana'), findsOneWidget);
      expect(find.byKey(const Key('activity_item_title')), findsOneWidget);
      expect(find.byKey(const Key('activity_item_price')), findsOneWidget);
      expect(find.text(strings.itemPriceLabel), findsOneWidget);
      expect(find.text('price_cents'), findsNothing);
      expect(find.text(strings.myWishlistsTitle), findsNothing);
      expect(find.textContaining('Secret Link'), findsNothing);
      expect(find.textContaining('enlace secreto'), findsNothing);
    });

    testWidgets('board reserve gift deliver and owner receive [REQ-RES-004] [REQ-GIFT-001] [REQ-ACT-005]', (
      tester,
    ) async {
      var reserved = false;
      var purchased = false;
      var delivered = false;
      final client = buildClient((req) {
        if (req.path.endsWith('/my_assignment')) {
          return const ApiResponse(statusCode: 200, body: {'assignment': null});
        }
        if (req.path == '/api/v1/my_reservations') {
          final holds = <Map<String, dynamic>>[];
          final gifts = <Map<String, dynamic>>[];
          if (reserved && !purchased) {
            holds.add({
              'id': 8,
              'item_id': 50,
              'status': 'active',
              'estimated_date': '2026-12-10',
              'activity_id': 7,
            });
          }
          if (purchased && !delivered) {
            gifts.add({
              'id': 3,
              'item_id': 50,
              'wishlist_id': 11,
              'activity_id': 7,
              'status': 'purchased_secret',
            });
          }
          return ApiResponse(
            statusCode: 200,
            body: {'reservations': holds, 'open_gifts': gifts},
          );
        }
        if (req.path == '/api/v1/activities/7') {
          return ApiResponse(statusCode: 200, body: {'activity': activityJson()});
        }
        if (req.path == '/api/v1/activities/7/wishlists') {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'wishlists': [
                {
                  'id': 11,
                  'title': 'Lista Peer',
                  'activity_id': 7,
                  'privacy_mode': 'friends',
                  'owner': {'id': 3, 'username': 'peer'},
                  'viewer_is_owner': false,
                },
              ],
            },
          );
        }
        if (req.path == '/api/v1/activities/7/wishlists/11/items' &&
            req.method == 'GET') {
          String? availability = 'available';
          if (reserved && !purchased) availability = 'reserved_by_me';
          if (purchased) availability = 'reserved_by_me';
          return ApiResponse(
            statusCode: 200,
            body: {
              'items': [
                {
                  'id': 50,
                  'wishlist_id': 11,
                  'title': 'Bufanda',
                  'priority': 'medium',
                  'price_cents': 800,
                  'currency': 'CRC',
                  'position': 0,
                  'links': [],
                  'images': [],
                  'availability': availability,
                },
              ],
            },
          );
        }
        if (req.path == '/api/v1/items/50/reservations' && req.method == 'POST') {
          reserved = true;
          return const ApiResponse(
            statusCode: 201,
            body: {
              'reservation': {
                'id': 8,
                'item_id': 50,
                'status': 'active',
                'estimated_date': '2026-12-10',
                'activity_id': 7,
              },
            },
          );
        }
        if (req.path == '/api/v1/reservations/8' && req.method == 'PATCH') {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'reservation': {
                'id': 8,
                'item_id': 50,
                'status': 'active',
                'estimated_date': '2026-12-20',
                'activity_id': 7,
              },
            },
          );
        }
        if (req.path == '/api/v1/reservations/8/mark_purchased') {
          purchased = true;
          reserved = false;
          return const ApiResponse(
            statusCode: 201,
            body: {
              'gift': {
                'id': 3,
                'item_id': 50,
                'wishlist_id': 11,
                'activity_id': 7,
                'status': 'purchased_secret',
              },
            },
          );
        }
        if (req.path == '/api/v1/gifts/3/mark_delivered') {
          delivered = true;
          return const ApiResponse(
            statusCode: 200,
            body: {
              'gift': {
                'id': 3,
                'item_id': 50,
                'activity_id': 7,
                'status': 'delivered_pending_confirmation',
              },
            },
          );
        }
        if (req.path.contains('/wishlists/11/items') && req.method == 'POST') {
          return const ApiResponse(
            statusCode: 422,
            body: {
              'errors': ['price breaks fixed budget'],
            },
          );
        }
        return const ApiResponse(statusCode: 200, body: {});
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityBoardScreen(
            activityRepository: ActivityRepository(apiClient: client),
            reservationRepository: ReservationRepository(apiClient: client),
            giftRepository: GiftRepository(apiClient: client),
            strings: strings,
            tokens: tokens,
            activityId: 7,
            viewerUserId: 9,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bufanda'), findsOneWidget);
      expect(find.text(strings.reserveButton), findsOneWidget);

      await tester.tap(find.text(strings.reserveButton));
      await tester.pumpAndSettle();
      expect(find.text(strings.extendReservationButton), findsOneWidget);
      expect(find.text(strings.markPurchasedButton), findsOneWidget);

      await tester.tap(find.text(strings.extendReservationButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.markPurchasedButton));
      await tester.pumpAndSettle();
      expect(find.text(strings.markDeliveredButton), findsOneWidget);

      await tester.tap(find.text(strings.markDeliveredButton));
      await tester.pumpAndSettle();
      expect(delivered, isTrue);
    });

    testWidgets('board owner mark received Path 2 [REQ-GIFT-003] [REQ-ACT-005]', (
      tester,
    ) async {
      var marked = false;
      final client = buildClient((req) {
        if (req.path.endsWith('/my_assignment')) {
          return const ApiResponse(statusCode: 200, body: {'assignment': null});
        }
        if (req.path == '/api/v1/my_reservations') {
          return const ApiResponse(
            statusCode: 200,
            body: {'reservations': [], 'open_gifts': []},
          );
        }
        if (req.path == '/api/v1/activities/7') {
          return ApiResponse(statusCode: 200, body: {'activity': activityJson()});
        }
        if (req.path == '/api/v1/activities/7/wishlists') {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'wishlists': [
                {
                  'id': 11,
                  'title': 'Mi lista',
                  'activity_id': 7,
                  'privacy_mode': 'friends',
                  'owner': {'id': 9, 'username': 'me'},
                  'viewer_is_owner': true,
                },
              ],
            },
          );
        }
        if (req.path == '/api/v1/activities/7/wishlists/11/items' &&
            req.method == 'GET') {
          return ApiResponse(
            statusCode: 200,
            body: {
              'items': [
                {
                  'id': 50,
                  'wishlist_id': 11,
                  'title': 'Taza',
                  'priority': 'medium',
                  'position': 0,
                  'links': [],
                  'images': [],
                  'received_gift': marked,
                },
              ],
            },
          );
        }
        if (req.path == '/api/v1/items/50/mark_received') {
          marked = true;
          return const ApiResponse(
            statusCode: 201,
            body: {
              'gift': {'id': 9, 'item_id': 50, 'status': 'received_confirmed'},
            },
          );
        }
        return const ApiResponse(statusCode: 200, body: {});
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityBoardScreen(
            activityRepository: ActivityRepository(apiClient: client),
            reservationRepository: ReservationRepository(apiClient: client),
            giftRepository: GiftRepository(apiClient: client),
            strings: strings,
            tokens: tokens,
            activityId: 7,
            viewerUserId: 9,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.markReceivedButton), findsOneWidget);
      await tester.tap(find.text(strings.markReceivedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.confirmReceivedButton));
      await tester.pumpAndSettle();
      expect(marked, isTrue);
      expect(find.text(strings.markReceivedButton), findsNothing);
    });

    testWidgets('activity lists are not under My Wishlists [REQ-ACT-001] FC1A', (
      tester,
    ) async {
      final client = buildClient((req) {
        if (req.path == '/api/v1/wishlists') {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'wishlists': [
                {
                  'id': 1,
                  'title': 'Personal Only',
                  'privacy_mode': 'friends',
                  'share_token': null,
                  'owner': {
                    'id': 9,
                    'username': 'me_user',
                    'created_at': '2026-11-26T10:00:00Z',
                  },
                },
              ],
            },
          );
        }
        return const ApiResponse(statusCode: 200, body: {});
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyWishlistsScreen(
              wishlistRepository: WishlistRepository(apiClient: client),
              strings: strings,
              tokens: tokens,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Personal Only'), findsOneWidget);
      expect(find.text('Lista Ana'), findsNothing);
      expect(find.text(strings.activityListsHeading), findsNothing);
    });

    testWidgets('prefs screen lists new activity B events [REQ-NOTIF-001] O6A', (
      tester,
    ) async {
      final client = buildClient((req) {
        return const ApiResponse(
          statusCode: 200,
          body: {
            'notification_preference': {
              'channels': {
                'activity.budget_rejected': {
                  'in_app': true,
                  'email': true,
                  'push': false,
                },
                'activity.reservation_grace_started': {
                  'in_app': true,
                  'email': true,
                  'push': true,
                },
              },
              'defaults_events': [
                'activity.budget_rejected',
                'activity.reservation_grace_started',
              ],
            },
          },
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationPrefsScreen(
            notificationRepository: NotificationRepository(apiClient: client),
            strings: strings,
            tokens: tokens,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('activity.budget_rejected'), findsWidgets);
      expect(
        find.textContaining('activity.reservation_grace_started'),
        findsWidgets,
      );
    });
  });
}
