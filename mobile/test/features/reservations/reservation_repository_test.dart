import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/features/reservations/reservation_repository.dart';

void main() {
  group('ReservationRepository [REQ-RES-001] [REQ-RES-004]', () {
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
      await tokenStorage.saveToken('res_bearer');
    });

    test('create posts reservation payload [REQ-RES-001]', () async {
      final client = buildMockClient((req) {
        expect(req.method, 'POST');
        expect(req.path, '/api/v1/items/9/reservations');
        return ApiResponse(
          statusCode: 201,
          body: {
            'reservation': {
              'id': 2,
              'item_id': 9,
              'status': 'active',
              'estimated_date': '2030-01-08',
            },
          },
        );
      });
      final repo = ReservationRepository(apiClient: client);
      final created = await repo.create(
        itemId: 9,
        estimatedDate: '2030-01-08',
      );
      expect(created.id, 2);
      expect(created.status, 'active');
    });

    test('fetchMineWithOpenGifts maps holds and gifts in one GET [REQ-RES-004] [REQ-GIFT-001]',
        () async {
      var calls = 0;
      final client = buildMockClient((req) {
        expect(req.path, '/api/v1/my_reservations');
        calls += 1;
        return ApiResponse(
          statusCode: 200,
          body: {
            'reservations': [
              {
                'id': 1,
                'item_id': 9,
                'wishlist_id': 3,
                'status': 'active',
                'estimated_date': '2030-01-01',
                'item_title': 'Libro',
                'wishlist_title': 'Fiesta',
              },
            ],
            'open_gifts': [
              {
                'id': 4,
                'item_id': 9,
                'wishlist_id': 3,
                'status': 'purchased_secret',
              },
            ],
          },
        );
      });
      final repo = ReservationRepository(apiClient: client);
      final bundle = await repo.fetchMineWithOpenGifts();
      expect(calls, 1);
      expect(bundle.reservations.single.itemTitle, 'Libro');
      expect(bundle.reservations.single.wishlistTitle, 'Fiesta');
      expect(bundle.openGifts.single.id, 4);
      expect(bundle.openGifts.single.status, 'purchased_secret');
    });
  });
}
