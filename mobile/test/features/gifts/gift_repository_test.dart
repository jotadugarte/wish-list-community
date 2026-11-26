import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/features/gifts/gift_repository.dart';

void main() {
  group('GiftRepository [REQ-GIFT-001] [REQ-GIFT-003] [REQ-GIFT-004]', () {
    late InMemoryTokenStorage tokenStorage;

    ApiClient buildMockClient(
      ApiResponse Function(RecordedApiRequest req) responder,
    ) {
      return ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async => responder(req),
      );
    }

    setUp(() async {
      tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('gift_bearer');
    });

    test('markPurchased posts to reservation mark_purchased [REQ-GIFT-001]', () async {
      final client = buildMockClient((req) {
        expect(req.method, 'POST');
        expect(req.path, '/api/v1/reservations/4/mark_purchased');
        return ApiResponse(
          statusCode: 201,
          body: {
            'gift': {
              'id': 9,
              'item_id': 3,
              'status': 'purchased_secret',
              'gifter_id': 2,
            },
          },
        );
      });
      final repo = GiftRepository(apiClient: client);
      final gift = await repo.markPurchased(reservationId: 4);
      expect(gift.id, 9);
      expect(gift.status, 'purchased_secret');
    });

    test('markDelivered posts gift member action [REQ-GIFT-001]', () async {
      final client = buildMockClient((req) {
        expect(req.path, '/api/v1/gifts/9/mark_delivered');
        return ApiResponse(
          statusCode: 200,
          body: {
            'gift': {'id': 9, 'item_id': 3, 'status': 'delivered_pending_confirmation'},
          },
        );
      });
      final repo = GiftRepository(apiClient: client);
      final gift = await repo.markDelivered(giftId: 9);
      expect(gift.status, 'delivered_pending_confirmation');
    });

    test('ownerMarkReceived posts Path 2 [REQ-GIFT-003]', () async {
      final client = buildMockClient((req) {
        expect(req.path, '/api/v1/items/3/mark_received');
        return ApiResponse(
          statusCode: 201,
          body: {
            'gift': {'id': 11, 'item_id': 3, 'status': 'received_confirmed', 'gifter_id': null},
          },
        );
      });
      final repo = GiftRepository(apiClient: client);
      final gift = await repo.ownerMarkReceived(itemId: 3, thankYouNote: 'Thanks');
      expect(gift.status, 'received_confirmed');
    });
  });
}
