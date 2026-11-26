import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/features/social/social_repository.dart';

void main() {
  group('SocialRepository [REQ-SOC-001] [REQ-WISH-001] [REQ-BLOCK-001] [REQ-DISC-001]', () {
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

    setUp(() async {
      tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('social_bearer_token');
      recordedRequests = [];
    });

    test('searchUsers validates SearchQueryVo and returns anti-stalking PublicUserCard list [REQ-SOC-001] [REQ-WISH-001]', () async {
      final client = buildMockClient((req) {
        expect(req.path, equals('/api/v1/users/search'));
        expect(req.queryParams?['q'], equals('nata_'));
        return const ApiResponse(
          statusCode: 200,
          body: {
            'users': [
              {
                'id': 2,
                'username': 'nata_friend',
                'friendship_status': 'accepted',
                'created_at': '2026-11-25T10:00:00Z',
              },
              {
                'id': 3,
                'username': 'nata_stranger',
                'friendship_status': 'none',
                'created_at': '2026-11-25T10:00:00Z',
              },
            ],
          },
        );
      });

      final repo = SocialRepository(apiClient: client);
      final cards = await repo.searchUsers('  @Nata_  ');

      expect(cards.length, equals(2));
      expect(cards.first.username.value, equals('nata_friend'));
      expect(cards.first.friendshipStatus, equals('accepted'));
      expect(cards.last.friendshipStatus, equals('none'));
    });

    test('fetchFriendships, sendFriendRequest, acceptFriendRequest, and removeFriendship manage friendships [REQ-SOC-001]', () async {
      final client = buildMockClient((req) {
        if (req.path == '/api/v1/friendships' && req.method == 'GET') {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'friends': [
                {
                  'id': 10,
                  'status': 'accepted',
                  'direction': 'outgoing',
                  'friend': {
                    'id': 2,
                    'username': 'bob_gifts',
                    'created_at': '2026-11-25T10:00:00Z',
                  },
                },
              ],
              'incoming_requests': [
                {
                  'id': 11,
                  'status': 'pending',
                  'direction': 'incoming',
                  'friend': {
                    'id': 4,
                    'username': 'charlie_peer',
                    'created_at': '2026-11-25T10:00:00Z',
                  },
                },
              ],
              'outgoing_requests': [],
            },
          );
        }
        if (req.path == '/api/v1/friendships' && req.method == 'POST') {
          return const ApiResponse(
            statusCode: 201,
            body: {
              'friendship': {
                'id': 12,
                'status': 'pending',
                'direction': 'outgoing',
                'friend': {
                  'id': 5,
                  'username': 'new_friend',
                  'created_at': '2026-11-25T10:00:00Z',
                },
              },
            },
          );
        }
        if (req.path == '/api/v1/friendships/11' && req.method == 'PATCH') {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'friendship': {
                'id': 11,
                'status': 'accepted',
                'direction': 'incoming',
                'friend': {
                  'id': 4,
                  'username': 'charlie_peer',
                  'created_at': '2026-11-25T10:00:00Z',
                },
              },
            },
          );
        }
        if (req.path == '/api/v1/friendships/11' && req.method == 'DELETE') {
          return const ApiResponse(statusCode: 204, body: {});
        }
        return const ApiResponse(statusCode: 404, body: {});
      });

      final repo = SocialRepository(apiClient: client);
      final summary = await repo.fetchFriendships();
      expect(summary.friends.length, equals(1));
      expect(summary.incomingRequests.length, equals(1));

      final sent = await repo.sendFriendRequest(addresseeId: 5);
      expect(sent.status, equals('pending'));

      final accepted = await repo.acceptFriendRequest(friendshipId: 11);
      expect(accepted.status, equals('accepted'));

      await repo.removeFriendship(friendshipId: 11);
      expect(recordedRequests.last.method, equals('DELETE'));
    });

    test('blockUser and reportUser invoke /api/v1/user_blocks and /api/v1/reports [REQ-BLOCK-001] [REQ-DISC-001]', () async {
      final client = buildMockClient((req) {
        if (req.path == '/api/v1/user_blocks') {
          return const ApiResponse(
            statusCode: 201,
            body: {'blocked_id': 9, 'status': 'blocked'},
          );
        }
        if (req.path == '/api/v1/reports') {
          return const ApiResponse(
            statusCode: 201,
            body: {
              'report': {
                'id': 1,
                'reportable_type': 'User',
                'reportable_id': 9,
                'reason': 'harassment',
                'status': 'pending',
              },
            },
          );
        }
        return const ApiResponse(statusCode: 404, body: {});
      });

      final repo = SocialRepository(apiClient: client);
      await repo.blockUser(blockedUserId: 9);
      await repo.reportUser(
        targetUserId: 9,
        rawReason: 'HARASSMENT',
        details: 'Spamming requests',
      );

      expect(recordedRequests.length, equals(2));
      expect(recordedRequests.last.body?['reason'], equals('harassment'));
    });
  });
}
