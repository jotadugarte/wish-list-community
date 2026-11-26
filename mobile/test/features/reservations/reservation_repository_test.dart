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

    test('fetchMine maps my_reservations [REQ-RES-004]', () async {
      final client = buildMockClient((req) {
        expect(req.path, '/api/v1/my_reservations');
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
          },
        );
      });
      final repo = ReservationRepository(apiClient: client);
      final mine = await repo.fetchMine();
      expect(mine.single.itemTitle, 'Libro');
      expect(mine.single.wishlistTitle, 'Fiesta');
    });
  });
}
