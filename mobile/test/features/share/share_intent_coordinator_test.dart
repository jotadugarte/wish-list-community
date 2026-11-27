import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wish_list_mobile/features/share/last_wishlist_memory.dart';
import 'package:wish_list_mobile/features/share/share_intent_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareIntentCoordinator O4B/O11A', () {
    late LastWishlistMemory memory;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      memory = LastWishlistMemory(await SharedPreferences.getInstance());
    });

    test('logged-out requires login then can resume with payload', () async {
      final coordinator = ShareIntentCoordinator(
        memory: memory,
        isLoggedIn: () => false,
        loadOwnedWishlistIds: () async => {1},
      );
      final decision = await coordinator.handleSharedText('see https://x.test/a');
      expect(decision.outcome, ShareIntentOutcome.requireLogin);
      expect(decision.payload.canOpenAddItem, isTrue);
    });

    test('logged-in skips picker when last wishlist still owned', () async {
      await memory.remember(5);
      final coordinator = ShareIntentCoordinator(
        memory: memory,
        isLoggedIn: () => true,
        loadOwnedWishlistIds: () async => {5, 9},
      );
      final decision = await coordinator.handleSharedText('https://x.test/a title');
      expect(decision.outcome, ShareIntentOutcome.skipPicker);
      expect(decision.wishlistId, 5);
    });

    test('logged-in shows picker when memory unsafe', () async {
      await memory.remember(5);
      final coordinator = ShareIntentCoordinator(
        memory: memory,
        isLoggedIn: () => true,
        loadOwnedWishlistIds: () async => {9},
      );
      final decision = await coordinator.handleSharedText('https://x.test/a');
      expect(decision.outcome, ShareIntentOutcome.showPicker);
    });

    test('cannot parse when no URL', () async {
      final coordinator = ShareIntentCoordinator(
        memory: memory,
        isLoggedIn: () => true,
        loadOwnedWishlistIds: () async => {1},
      );
      final decision = await coordinator.handleSharedText('no link here');
      expect(decision.outcome, ShareIntentOutcome.cannotParse);
    });
  });
}
