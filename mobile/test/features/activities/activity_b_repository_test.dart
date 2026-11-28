import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/features/activities/activity_repository.dart';
import 'package:wish_list_mobile/features/gifts/gift_repository.dart';
import 'package:wish_list_mobile/features/notifications/notification_repository.dart';
import 'package:wish_list_mobile/features/reservations/reservation_repository.dart';

void main() {
  group('Activity B repository [REQ-MOB-001] [REQ-ACT-005] [REQ-RES-005]', () {
    late InMemoryTokenStorage tokenStorage;
    late List<RecordedApiRequest> recorded;

    ApiClient buildClient(ApiResponse Function(RecordedApiRequest req) responder) {
      return ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async {
          recorded.add(req);
          return responder(req);
        },
      );
    }

    setUp(() async {
      tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('tok');
      recorded = [];
    });

    test('fetches activity wishlists and creates priced item [REQ-ACT-005]', () async {
      final client = buildClient((req) {
        if (req.path == '/api/v1/activities/7/wishlists' && req.method == 'GET') {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'wishlists': [
                {
                  'id': 11,
                  'title': 'Hotwire B',
                  'activity_id': 7,
                  'privacy_mode': 'friends',
                  'owner': {'id': 2, 'username': 'ana'},
                },
              ],
            },
          );
        }
        if (req.path == '/api/v1/activities/7/wishlists/11/items' &&
            req.method == 'POST') {
          final item = req.body?['item'] as Map<String, dynamic>?;
          expect(item?['title'], 'Libro');
          expect(item?['price_cents'], 1500);
          expect(item?['currency'], 'CRC');
          return const ApiResponse(
            statusCode: 201,
            body: {
              'item': {
                'id': 99,
                'wishlist_id': 11,
                'title': 'Libro',
                'priority': 'medium',
                'price_cents': 1500,
                'currency': 'CRC',
                'position': 0,
                'links': [],
                'images': [],
              },
            },
          );
        }
        fail('Unexpected ${req.method} ${req.path}');
      });
      final repo = ActivityRepository(apiClient: client);

      final lists = await repo.fetchActivityWishlists(activityId: 7);
      expect(lists, hasLength(1));
      expect(lists.first.id, 11);
      expect(lists.first.activityId, 7);
      expect(lists.first.shareToken, isNull);

      final item = await repo.createActivityItem(
        activityId: 7,
        wishlistId: 11,
        title: 'Libro',
        priceCents: 1500,
        currency: 'CRC',
      );
      expect(item.title, 'Libro');
      expect(item.priceCents, 1500);
    });

    test('surfaces budget and reservation limit errors [REQ-ACT-005] [REQ-RES-005]', () async {
      final client = buildClient((req) {
        if (req.path.contains('/items') && req.method == 'POST') {
          return const ApiResponse(
            statusCode: 422,
            body: {
              'errors': ['price breaks fixed budget'],
            },
          );
        }
        if (req.path.endsWith('/reservation_limit')) {
          return const ApiResponse(
            statusCode: 422,
            body: {
              'errors': ['reservation limit frozen after seal'],
            },
          );
        }
        fail('Unexpected ${req.method} ${req.path}');
      });
      final repo = ActivityRepository(apiClient: client);

      expect(
        () => repo.createActivityItem(
          activityId: 7,
          wishlistId: 11,
          title: 'Caro',
          priceCents: 2500,
          currency: 'CRC',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('budget'),
          ),
        ),
      );

      expect(
        () => repo.setReservationLimit(activityId: 7, maxReservationsPerUser: 5),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('limit'),
          ),
        ),
      );
    });

    test('sets open_gifting reservation limit pre-seal [REQ-RES-005]', () async {
      final client = buildClient((req) {
        expect(req.method, 'PATCH');
        expect(req.path, '/api/v1/activities/7/reservation_limit');
        expect(req.body?['max_reservations_per_user'], 3);
        return const ApiResponse(
          statusCode: 200,
          body: {'max_reservations_per_user': 3},
        );
      });
      final repo = ActivityRepository(apiClient: client);
      final n = await repo.setReservationLimit(
        activityId: 7,
        maxReservationsPerUser: 3,
      );
      expect(n, 3);
    });

    test('reserves extends cancels and gifts activity items via existing repos [REQ-RES-004]', () async {
      final client = buildClient((req) {
        if (req.path == '/api/v1/items/50/reservations' && req.method == 'POST') {
          return const ApiResponse(
            statusCode: 201,
            body: {
              'reservation': {
                'id': 8,
                'item_id': 50,
                'status': 'active',
                'estimated_date': '2026-12-10',
                'activity_id': 7,
                'item_title': 'Bufanda',
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
          return const ApiResponse(
            statusCode: 201,
            body: {
              'gift': {
                'id': 3,
                'item_id': 50,
                'status': 'purchased_secret',
              },
            },
          );
        }
        if (req.path == '/api/v1/gifts/3/mark_delivered') {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'gift': {
                'id': 3,
                'item_id': 50,
                'status': 'delivered_pending_confirmation',
              },
            },
          );
        }
        if (req.path == '/api/v1/reservations/8' && req.method == 'DELETE') {
          return const ApiResponse(statusCode: 204, body: {});
        }
        fail('Unexpected ${req.method} ${req.path}');
      });

      final reservations = ReservationRepository(apiClient: client);
      final gifts = GiftRepository(apiClient: client);

      final hold = await reservations.create(
        itemId: 50,
        estimatedDate: '2026-12-10',
      );
      expect(hold.activityId, 7);
      expect(hold.status, 'active');

      final extended = await reservations.extend(
        reservationId: 8,
        estimatedDate: '2026-12-20',
      );
      expect(extended.estimatedDate, '2026-12-20');

      final gift = await gifts.markPurchased(reservationId: 8);
      expect(gift.status, 'purchased_secret');
      final delivered = await gifts.markDelivered(giftId: 3);
      expect(delivered.status, 'delivered_pending_confirmation');

      await reservations.cancel(reservationId: 8);
    });

    test('prefs catalog includes Sprint B activity events [REQ-NOTIF-001] O6A', () async {
      const bEvents = [
        'activity.item_touched_while_reserved',
        'activity.reservation_created',
        'activity.reservation_released',
        'activity.reservation_grace_started',
        'activity.reservation_auto_released',
        'activity.gift_purchased',
        'activity.gift_delivered',
        'activity.gift_received',
        'activity.budget_rejected',
      ];
      final client = buildClient((req) {
        expect(req.path, '/api/v1/notification_preferences');
        return ApiResponse(
          statusCode: 200,
          body: {
            'notification_preference': {
              'channels': {
                for (final e in bEvents) e: {'in_app': true, 'email': true, 'push': true},
              },
              'defaults_events': bEvents,
            },
          },
        );
      });
      final prefs = await NotificationRepository(apiClient: client).fetchPreferences();
      for (final key in bEvents) {
        expect(prefs.defaultsEvents, contains(key));
        expect(prefs.channelEnabled(key, 'in_app'), isTrue);
      }
    });
  });
}
