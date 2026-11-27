import 'package:shared_preferences/shared_preferences.dart';

// Device-local last owned wishlist id for Share-to-App skip-picker (O11A).
// Traceability: [REQ-WISH-001]
class LastWishlistMemory {
  static const _key = 'share_last_wishlist_id';

  final SharedPreferences prefs;

  LastWishlistMemory(this.prefs);

  Future<void> remember(int wishlistId) async {
    if (wishlistId <= 0) {
      throw ArgumentError('Pre-condition failed: wishlistId must be > 0');
    }
    await prefs.setInt(_key, wishlistId);
  }

  int? read() {
    final id = prefs.getInt(_key);
    if (id == null || id <= 0) return null;
    return id;
  }

  Future<void> clear() async {
    await prefs.remove(_key);
  }

  /// Returns remembered id only when still owned by current user.
  int? safeOwnedId({required Set<int> ownedWishlistIds}) {
    final id = read();
    if (id == null) return null;
    if (!ownedWishlistIds.contains(id)) {
      return null;
    }
    return id;
  }
}
