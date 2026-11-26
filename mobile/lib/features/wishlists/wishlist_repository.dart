import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/values/domain_values.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_models.dart';

export 'package:wish_list_mobile/features/wishlists/wishlist_models.dart';

// Repository for Sprint 3 wishlist shells, Shared-with-me, and friend discovery.
// Traceability: [REQ-WISH-001], [REQ-WISH-002], [REQ-WISH-003], [REQ-WISH-006]
class WishlistRepository {
  static const int maxList = 100;

  final ApiClient apiClient;

  const WishlistRepository({required this.apiClient});

  // [REQ-WISH-001] Lists the authenticated user's wishlists.
  Future<List<WishlistShell>> fetchMyWishlists() async {
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/wishlists',
    );
    return _parseList(response.body['wishlists']);
  }

  // [REQ-WISH-001] Creates a wishlist (server defaults privacy_mode=friends).
  Future<WishlistShell> createWishlist({
    required String title,
    String? eventDate,
  }) async {
    final cleaned = title.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('Pre-condition failed: title cannot be blank');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/wishlists',
      body: {
        'wishlist': {
          'title': cleaned,
          'event_date': ?eventDate,
        },
      },
    );
    final shell = WishlistShell.fromJson(
      response.body['wishlist'] as Map<String, dynamic>,
    );
    if (shell.privacyMode != 'friends') {
      throw StateError('Post-condition failed: default privacy must be friends');
    }
    return shell;
  }

  // [REQ-WISH-001] [REQ-WISH-002] Updates title/event_date/privacy_mode.
  Future<WishlistShell> updateWishlist({
    required int wishlistId,
    String? title,
    String? eventDate,
    String? privacyMode,
  }) async {
    if (wishlistId <= 0) {
      throw ArgumentError('Pre-condition failed: wishlistId must be > 0');
    }
    final response = await apiClient.request(
      method: 'PATCH',
      path: '/api/v1/wishlists/$wishlistId',
      body: {
        'wishlist': {
          'title': ?title,
          'event_date': ?eventDate,
          'privacy_mode': ?privacyMode,
        },
      },
    );
    return WishlistShell.fromJson(
      response.body['wishlist'] as Map<String, dynamic>,
    );
  }

  // [REQ-WISH-002] [REQ-WISH-006] Rotates Secret Link token while staying shared.
  Future<WishlistShell> rotateShareToken({required int wishlistId}) async {
    if (wishlistId <= 0) {
      throw ArgumentError('Pre-condition failed: wishlistId must be > 0');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/wishlists/$wishlistId/share_token/rotate',
    );
    return WishlistShell.fromJson(
      response.body['wishlist'] as Map<String, dynamic>,
    );
  }

  // [REQ-WISH-003] Lists Shared-with-me wishlists.
  Future<List<WishlistShell>> fetchSharedWishlists() async {
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/shared_wishlists',
    );
    return _parseList(response.body['wishlists']);
  }

  // [REQ-WISH-001] Lists accessible wishlists for a username (O3A).
  Future<List<WishlistShell>> fetchUserWishlists(String rawUsername) async {
    final username = UsernameVo(rawUsername);
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/users/${username.value}/wishlists',
    );
    return _parseList(response.body['wishlists']);
  }

  // [REQ-WISH-001] Fetches one wishlist shell by id.
  Future<WishlistShell> fetchWishlist(int wishlistId) async {
    if (wishlistId <= 0) {
      throw ArgumentError('Pre-condition failed: wishlistId must be > 0');
    }
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/wishlists/$wishlistId',
    );
    return WishlistShell.fromJson(
      response.body['wishlist'] as Map<String, dynamic>,
    );
  }

  List<WishlistShell> _parseList(Object? raw) {
    final items = (raw as List<dynamic>? ?? const []).take(maxList);
    final list = items
        .map((e) => WishlistShell.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    if (list.length > maxList) {
      throw StateError('Post-condition failed: wishlist list exceeded bound');
    }
    return list;
  }
}
