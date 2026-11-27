import 'package:wish_list_mobile/core/values/share_payload.dart';
import 'package:wish_list_mobile/features/share/last_wishlist_memory.dart';

enum ShareIntentOutcome {
  requireLogin,
  cannotParse,
  skipPicker,
  showPicker,
}

class ShareIntentDecision {
  final ShareIntentOutcome outcome;
  final SharePayload payload;
  final int? wishlistId;

  const ShareIntentDecision({
    required this.outcome,
    required this.payload,
    this.wishlistId,
  });
}

// Share-to-App entry: login resume, skip-picker when last list safe, else picker.
// Traceability: [REQ-ITEM-006] O4B / O11A
class ShareIntentCoordinator {
  final LastWishlistMemory memory;
  bool Function() isLoggedIn;
  Future<Set<int>> Function() loadOwnedWishlistIds;

  ShareIntentCoordinator({
    required this.memory,
    required this.isLoggedIn,
    required this.loadOwnedWishlistIds,
  });

  Future<ShareIntentDecision> handleSharedText(String raw) async {
    final payload = SharePayload.parse(raw);
    if (!payload.canOpenAddItem) {
      return ShareIntentDecision(outcome: ShareIntentOutcome.cannotParse, payload: payload);
    }
    if (!isLoggedIn()) {
      return ShareIntentDecision(outcome: ShareIntentOutcome.requireLogin, payload: payload);
    }

    final owned = await loadOwnedWishlistIds();
    final safeId = memory.safeOwnedId(ownedWishlistIds: owned);
    if (safeId != null) {
      return ShareIntentDecision(
        outcome: ShareIntentOutcome.skipPicker,
        payload: payload,
        wishlistId: safeId,
      );
    }
    return ShareIntentDecision(outcome: ShareIntentOutcome.showPicker, payload: payload);
  }

  Future<void> rememberChosenWishlist(int wishlistId) => memory.remember(wishlistId);
}
