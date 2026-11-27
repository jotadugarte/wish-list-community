import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/features/share/deep_link_router.dart';

void main() {
  group('DeepLinkRouter O3A/O9B', () {
    final router = DeepLinkRouter(allowedHosts: {'staging.example'});

    test('routes friend profile', () {
      final d = router.resolve(Uri.parse('https://staging.example/u/bob_user'));
      expect(d.route, DeepLinkRoute.friendProfile);
      expect(d.username, 'bob_user');
    });

    test('routes secret link', () {
      final d = router.resolve(Uri.parse('https://staging.example/s/tok_1'));
      expect(d.route, DeepLinkRoute.secretLink);
      expect(d.shareToken, 'tok_1');
    });

    test('safe failure for unsupported', () {
      final d = router.resolve(Uri.parse('https://staging.example/activities/1'));
      expect(d.route, DeepLinkRoute.safeFailure);
    });

    test('safe failure for unknown host', () {
      final d = router.resolve(Uri.parse('https://evil.example/u/bob_user'));
      expect(d.route, DeepLinkRoute.safeFailure);
    });

    test('routes wishlist://u/username custom scheme [REQ-SOC-001]', () {
      final d = router.resolve(Uri.parse('wishlist://u/alice_01'));
      expect(d.route, DeepLinkRoute.friendProfile);
      expect(d.username, 'alice_01');
    });

    test('routes wishlist://s/token custom scheme [REQ-WISH-005]', () {
      final d = router.resolve(Uri.parse('wishlist://s/tok_Ab-12'));
      expect(d.route, DeepLinkRoute.secretLink);
      expect(d.shareToken, 'tok_Ab-12');
    });

    test('normalizeCustomScheme rewrites host-style wishlist URIs', () {
      final normalized = DeepLinkRouter.normalizeCustomScheme(
        Uri.parse('wishlist://u/bob_user'),
      );
      expect(normalized.host, isEmpty);
      expect(normalized.path, '/u/bob_user');
    });
  });
}
