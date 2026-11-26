import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/values/domain_values.dart';
import 'package:wish_list_mobile/features/social/social_models.dart';

export 'package:wish_list_mobile/features/social/social_models.dart';

// Repository consuming Sprint 2 Social Graph, Anti-Stalking Search, Blocking, and Reporting endpoints.
// Traceability: [REQ-SOC-001], [REQ-WISH-001], [REQ-BLOCK-001], [REQ-DISC-001]
class SocialRepository {
  static const int maxSearchResults = 20;

  final ApiClient apiClient;

  const SocialRepository({required this.apiClient});

  // [REQ-SOC-001] [REQ-WISH-001] [REQ-BLOCK-001] Searches users by @username prefix via SearchQueryVo.
  Future<List<PublicUserCard>> searchUsers(String rawQuery) async {
    final queryVo = SearchQueryVo(rawQuery);
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/users/search',
      queryParams: {'q': queryVo.value},
    );

    final rawList = (response.body['users'] as List<dynamic>? ?? const []).take(
      maxSearchResults,
    );
    final cards = rawList
        .map((e) => PublicUserCard.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    if (cards.length > maxSearchResults) {
      throw StateError('Post-condition failed: search results exceeded bound');
    }
    return cards;
  }

  // [REQ-SOC-001] Fetches accepted friends, incoming requests, and outgoing requests.
  Future<FriendshipsSummary> fetchFriendships() async {
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/friendships',
    );

    List<FriendshipItem> parseList(String key) {
      final items = (response.body[key] as List<dynamic>? ?? const []).take(
        500,
      );
      return items
          .map((e) => FriendshipItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    return FriendshipsSummary(
      friends: parseList('friends'),
      incomingRequests: parseList('incoming_requests'),
      outgoingRequests: parseList('outgoing_requests'),
    );
  }

  // [REQ-SOC-001] [REQ-BLOCK-001] Sends a pending friend request to addresseeId.
  Future<FriendshipItem> sendFriendRequest({required int addresseeId}) async {
    if (addresseeId <= 0) {
      throw ArgumentError('Pre-condition failed: addresseeId must be > 0');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/friendships',
      body: {'addressee_id': addresseeId},
    );
    return FriendshipItem.fromJson(
      response.body['friendship'] as Map<String, dynamic>,
    );
  }

  // [REQ-SOC-001] Accepts an incoming pending friend request.
  Future<FriendshipItem> acceptFriendRequest({
    required int friendshipId,
  }) async {
    if (friendshipId <= 0) {
      throw ArgumentError('Pre-condition failed: friendshipId must be > 0');
    }
    final response = await apiClient.request(
      method: 'PATCH',
      path: '/api/v1/friendships/$friendshipId',
    );
    return FriendshipItem.fromJson(
      response.body['friendship'] as Map<String, dynamic>,
    );
  }

  // [REQ-SOC-001] Declines, cancels, or removes a friendship.
  Future<void> removeFriendship({required int friendshipId}) async {
    if (friendshipId <= 0) {
      throw ArgumentError('Pre-condition failed: friendshipId must be > 0');
    }
    await apiClient.request(
      method: 'DELETE',
      path: '/api/v1/friendships/$friendshipId',
    );
  }

  // [REQ-BLOCK-001] [REQ-BLOCK-002] Blocks a user via POST /api/v1/user_blocks.
  Future<void> blockUser({required int blockedUserId}) async {
    if (blockedUserId <= 0) {
      throw ArgumentError('Pre-condition failed: blockedUserId must be > 0');
    }
    await apiClient.request(
      method: 'POST',
      path: '/api/v1/user_blocks',
      body: {'blocked_id': blockedUserId},
    );
  }

  // [REQ-SOC-001] [REQ-DISC-001] Submits a user abuse report validated by ReportReasonVo.
  Future<void> reportUser({
    required int targetUserId,
    required String rawReason,
    String? details,
  }) async {
    if (targetUserId <= 0) {
      throw ArgumentError('Pre-condition failed: targetUserId must be > 0');
    }
    final reasonVo = ReportReasonVo(rawReason);
    await apiClient.request(
      method: 'POST',
      path: '/api/v1/reports',
      body: {
        'reportable_type': 'User',
        'reportable_id': targetUserId,
        'reason': reasonVo.value,
        'details': ?details,
      },
    );
  }
}
