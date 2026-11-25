import 'package:wish_list_mobile/core/values/domain_values.dart';

// Anti-stalking public profile card containing only id, @username, and friendshipStatus.
// Never contains email_address or personal wishlists.
// Traceability: [REQ-SOC-001], [REQ-WISH-001], [REQ-USER-001]
class PublicUserCard {
  final int id;
  final UsernameVo username;
  final String friendshipStatus;

  const PublicUserCard({
    required this.id,
    required this.username,
    this.friendshipStatus = 'none',
  });

  // [REQ-SOC-001] Parses public profile JSON card using UsernameVo.
  factory PublicUserCard.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! int) {
      throw ArgumentError('Pre-condition failed: public user id must be int');
    }
    return PublicUserCard(
      id: rawId,
      username: UsernameVo(json['username'] as String),
      friendshipStatus: (json['friendship_status'] as String?) ?? 'none',
    );
  }
}

// Represents a Friendship or pending friend request from /api/v1/friendships.
// Traceability: [REQ-SOC-001]
class FriendshipItem {
  final int id;
  final String status;
  final String direction;
  final PublicUserCard friend;

  const FriendshipItem({
    required this.id,
    required this.status,
    required this.direction,
    required this.friend,
  });

  // [REQ-SOC-001] Parses a friendship item from API JSON.
  factory FriendshipItem.fromJson(Map<String, dynamic> json) {
    return FriendshipItem(
      id: json['id'] as int,
      status: json['status'] as String,
      direction: (json['direction'] as String?) ?? 'outgoing',
      friend: PublicUserCard.fromJson(json['friend'] as Map<String, dynamic>),
    );
  }
}

class FriendshipsSummary {
  final List<FriendshipItem> friends;
  final List<FriendshipItem> incomingRequests;
  final List<FriendshipItem> outgoingRequests;

  const FriendshipsSummary({
    required this.friends,
    required this.incomingRequests,
    required this.outgoingRequests,
  });
}
