import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_repository.dart';

void main() {
  group('WishlistRepository [REQ-WISH-001] [REQ-WISH-002] [REQ-WISH-003] [REQ-WISH-006]', () {
    late InMemoryTokenStorage tokenStorage;
    late List<RecordedApiRequest> recordedRequests;

    ApiClient buildMockClient(
      ApiResponse Function(RecordedApiRequest req) responder,
    ) {
      return ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async {
          recordedRequests.add(req);
          return responder(req);
        },
      );
    }

    Map<String, dynamic> shellJson({
      int id = 1,
      String privacy = 'friends',
      String? token,
    }) {
      return {
        'id': id,
        'title': 'Cumpleaños',
        'privacy_mode': privacy,
        'share_token': token,
        'event_date': null,
        'owner': {
          'id': 9,
          'username': 'owner_handle',
          'created_at': '2026-11-26T10:00:00Z',
        },
      };
    }

    setUp(() async {
      tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('wishlist_bearer');
      recordedRequests = [];
    });

    test('createWishlist defaults to friends privacy [REQ-WISH-001]', () async {
      final client = buildMockClient((req) {
        expect(req.method, equals('POST'));
        expect(req.path, equals('/api/v1/wishlists'));
        return ApiResponse(
          statusCode: 201,
          body: {'wishlist': shellJson()},
        );
      });
      final repo = WishlistRepository(apiClient: client);
      final created = await repo.createWishlist(title: 'Cumpleaños');
      expect(created.privacyMode, equals('friends'));
      expect(created.shareToken, isNull);
    });

    test('updateWishlist and rotateShareToken manage shared mode [REQ-WISH-002] [REQ-WISH-006]', () async {
      final client = buildMockClient((req) {
        if (req.path.endsWith('/share_token/rotate')) {
          return ApiResponse(
            statusCode: 200,
            body: {
              'wishlist': shellJson(privacy: 'shared', token: 'newTokenValue123456789012'),
            },
          );
        }
        return ApiResponse(
          statusCode: 200,
          body: {
            'wishlist': shellJson(privacy: 'shared', token: 'oldTokenValue123456789012'),
          },
        );
      });
      final repo = WishlistRepository(apiClient: client);
      final shared = await repo.updateWishlist(
        wishlistId: 1,
        privacyMode: 'shared',
      );
      expect(shared.isShared, isTrue);
      final rotated = await repo.rotateShareToken(wishlistId: 1);
      expect(rotated.shareToken, equals('newTokenValue123456789012'));
    });

    test('fetchSharedWishlists and fetchUserWishlists call O3A endpoints [REQ-WISH-003] [REQ-WISH-001]', () async {
      final client = buildMockClient((req) {
        if (req.path == '/api/v1/shared_wishlists') {
          return ApiResponse(
            statusCode: 200,
            body: {
              'wishlists': [shellJson(id: 2, privacy: 'shared', token: 'abc')],
            },
          );
        }
        expect(req.path, equals('/api/v1/users/friend_user/wishlists'));
        return ApiResponse(
          statusCode: 200,
          body: {
            'wishlists': [shellJson(id: 3)],
          },
        );
      });
      final repo = WishlistRepository(apiClient: client);
      final shared = await repo.fetchSharedWishlists();
      expect(shared.first.id, equals(2));
      final friendLists = await repo.fetchUserWishlists('friend_user');
      expect(friendLists.first.id, equals(3));
    });
  });
}
