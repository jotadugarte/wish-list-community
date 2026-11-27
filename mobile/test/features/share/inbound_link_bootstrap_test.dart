import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wish_list_mobile/features/share/deep_link_router.dart';
import 'package:wish_list_mobile/features/share/inbound_link_bootstrap.dart';
import 'package:wish_list_mobile/features/share/last_wishlist_memory.dart';
import 'package:wish_list_mobile/features/share/share_intent_coordinator.dart';
import 'package:wish_list_mobile/features/share/share_intent_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('InboundLinkBootstrap forwards share text to coordinator [REQ-MOB-001]', () async {
    SharedPreferences.setMockInitialValues({});
    final memory = LastWishlistMemory(await SharedPreferences.getInstance());
    final source = FakeShareIntentSource();
    ShareIntentDecision? seen;
    final bootstrap = InboundLinkBootstrap(
      shareSource: source,
      shareCoordinator: ShareIntentCoordinator(
        memory: memory,
        isLoggedIn: () => false,
        loadOwnedWishlistIds: () async => {},
      ),
      deepLinkRouter: DeepLinkRouter(allowedHosts: {'staging.wishlist.local'}),
      onShareDecision: (d) async => seen = d,
      onDeepLink: (_) async {},
      appLinks: null,
    );
    await bootstrap.start();
    source.emit('https://shop.example/item');
    await Future<void>.delayed(Duration.zero);
    expect(seen?.outcome, ShareIntentOutcome.requireLogin);
    await bootstrap.dispose();
  });
}
