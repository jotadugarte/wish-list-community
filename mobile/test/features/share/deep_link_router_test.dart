import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/values/domain_values.dart';
import 'package:wish_list_mobile/features/share/deep_link_router.dart';

void main() {
  group('DeepLinkRouter [REQ-MOB-001] [REQ-WISH-005] O3A/O9B', () {
    final router = DeepLinkRouter(allowedHosts: {'staging.example'});
    const longToken = 'tok_AbCdEfGhIjKlMnOpQrStUv';

    test('routes friend profile', () {
      final d = router.resolve(Uri.parse('https://staging.example/u/bob_user'));
      expect(d.route, DeepLinkRoute.friendProfile);
      expect(d.username, UsernameVo('bob_user'));
    });

    test('routes secret link', () {
      final d = router.resolve(Uri.parse('https://staging.example/s/$longToken'));
      expect(d.route, DeepLinkRoute.secretLink);
      expect(d.shareToken, ShareTokenVo(longToken));
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
      expect(d.username, UsernameVo('alice_01'));
    });

    test('routes wishlist://s/token custom scheme [REQ-WISH-005]', () {
      final d = router.resolve(Uri.parse('wishlist://s/$longToken'));
      expect(d.route, DeepLinkRoute.secretLink);
      expect(d.shareToken, ShareTokenVo(longToken));
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
