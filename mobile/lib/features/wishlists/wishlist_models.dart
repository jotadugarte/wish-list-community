import 'package:wish_list_mobile/core/values/domain_values.dart';

// Empty wishlist shell for Sprint 3 (no items).
// Traceability: [REQ-WISH-001], [REQ-WISH-002], [REQ-WISH-006]
class WishlistShell {
  final int id;
  final String title;
  final String privacyMode;
  final String? shareToken;
  final String? eventDate;
  final int? maxReservationsPerUser;
  final UsernameVo ownerUsername;

  const WishlistShell({
    required this.id,
    required this.title,
    required this.privacyMode,
    required this.ownerUsername,
    this.shareToken,
    this.eventDate,
    this.maxReservationsPerUser,
  });

  bool get isShared => privacyMode == 'shared';
  bool get isFriends => privacyMode == 'friends';

  // [REQ-WISH-001] Parses a wishlist JSON shell from /api/v1.
  factory WishlistShell.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! int) {
      throw ArgumentError('Pre-condition failed: wishlist id must be int');
    }
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    return WishlistShell(
      id: rawId,
      title: json['title'] as String? ?? '',
      privacyMode: json['privacy_mode'] as String? ?? 'friends',
      shareToken: json['share_token'] as String?,
      eventDate: json['event_date'] as String?,
      maxReservationsPerUser: json['max_reservations_per_user'] as int?,
      ownerUsername: UsernameVo(owner['username'] as String? ?? 'unknown'),
    );
  }
}
